#!/bin/bash
set -e

REPO_DIR="/data/data/com.termux/files/home/datasets"
LOG="$REPO_DIR/generator.log"
LOCK="$REPO_DIR/.generate.lock"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
GH="/data/data/com.termux/files/usr/bin/gh"

acquire_lock() {
    # Clean stale lock (file or directory leftover from crashed run)
    if [ -e "$LOCK" ]; then
        rm -rf "$LOCK"
    fi
    if ! mkdir "$LOCK" 2>/dev/null; then
        echo "[$(date '+%H:%M:%S')] ABORTED: another instance running" >> "$LOG"
        exit 1
    fi
}

log() {
    echo "[$(date '+%H:%M:%S')] $1" >> "$LOG"
}

trap 'rm -f "$LOCK" 2>/dev/null' EXIT

cd "$REPO_DIR"

# ==== image-01 ====
gen_image_01() {
    local prompts=(
        "A serene mountain lake at golden hour with reflections"
        "Cyberpunk cityscape with neon-lit streets and flying cars"
        "A cozy coffee shop interior with warm lighting"
        "Ancient temple ruins covered in tropical vegetation"
        "Abstract geometric art with vibrant color gradients"
        "A majestic wolf standing on a rocky cliff"
        "Underwater coral reef teeming with colorful fish"
        "Minimalist geometric pattern with pastel colors"
        "A steaming bowl of ramen with chopsticks"
        "Dramatic storm clouds over open farmland"
        "Abstract digital art with flowing light streams"
        "A detailed botanical illustration of exotic flowers"
        "Futuristic architecture with glass and steel"
        "Vintage map with compass and navigation elements"
        "A whimsy hedgehog character in a forest setting"
        "A field of sunflowers under a bright blue sky"
        "Steampunk mechanical owl with brass gears and clockwork"
        "A cozy reading nook with books and soft blankets"
        "Bioluminescent cave with glowing mushrooms"
        "A futuristic city at night with holographic advertisements"
        "A coral reef teeming with tropical fish at sunset"
        "A steampunk airship floating above fluffy clouds"
        "A wizard's library with floating books and magical chandelier"
    )

    local count=3
    for i in $(seq 1 $count); do
        prompt="${prompts[$((RANDOM % ${#prompts[@]}))]}"
        output="images/image_01/img_${TIMESTAMP}_${i}.png"
        mkdir -p "images/image_01"
        log "image-01: ${prompt:0:50}..."
        mmx image generate --prompt "$prompt" --out "$output" --quiet 2>/dev/null && log "Saved: $output" || log "FAILED: image-01 $i"
        sleep 15
    done
}

# ==== speech-2.8-hd ====
gen_speech_hd() {
    local texts=(
        "Welcome to the future of artificial intelligence. Today we explore the boundaries of creativity and technology working together as one."
        "In the depths of the ocean, light filters through the water in beautiful patterns. Life thrives in the most unexpected places."
        "The old library held secrets in every book. Dust motes danced in beams of light that streamed through tall windows."
        "Music is the universal language that connects all souls across time and space. Let the rhythm guide your heart."
        "Walking through the ancient forest, one can feel the wisdom of centuries-old trees. Nature teaches patience and resilience."
        "The city never sleeps. Neon lights paint the night sky as people chase their dreams under the stars."
        "Science and art are two sides of the same coin. Both seek to understand the beauty hidden in the fabric of reality."
        "Every sunset brings the promise of a new dawn. Hope persists even in the darkest of times."
        "The ancient warrior prepared for battle, knowing that courage is not the absence of fear, but the decision to act despite it."
        "In the kitchen, ingredients come together like old friends, creating dishes that nourish both body and soul."
        "The stars have witnessed countless stories throughout human history and beyond."
    )

    local count=2
    for i in $(seq 1 $count); do
        text="${texts[$((RANDOM % ${#texts[@]}))]}"
        output="speech/speech_28_hd/speech_${TIMESTAMP}_${i}.mp3"
        mkdir -p "speech/speech_28_hd"
        log "speech-2.8-hd: ${text:0:50}..."
        mmx speech synthesize --text "$text" --model speech-2.8-hd --out "$output" --quiet 2>/dev/null && log "Saved: $output" || log "FAILED: speech $i"
        sleep 10
    done
}

# ==== music-2.6 ====
gen_music_26() {
    local prompts=(
        "Upbeat electronic dance music with pulsing bass and uplifting melodies perfect for a party atmosphere"
        "Peaceful acoustic instrumental with gentle guitar and soft piano creating a calm meditation atmosphere"
        "Epic cinematic orchestral with dramatic drums and soaring strings for an adventurous journey"
        "Lo-fi hip hop chill beats with vinyl crackle and mellow saxophone for relaxed study sessions"
        "Energetic rock anthem with electric guitars and powerful drums inspiring determination and strength"
        "Ambient soundscape with nature sounds and ethereal synths for deep focus and concentration"
        "Jazz fusion with smooth saxophone solos and funky bass lines in a late-night lounge style"
        "Pop ballad with emotional vocals and piano accompaniment telling a story of love and loss"
        "Traditional folk melody with acoustic instruments and harmonized vocals celebrating cultural heritage"
        "Electronic synthwave with retro synthesizers and driving beats reminiscent of 80s sci-fi movies"
        "Classical piano piece with gentle melodic passages in the style of Debussy"
        "Reggae groove with laid-back rhythm guitar and expressive organ sounds"
    )

    local count=1
    for i in $(seq 1 $count); do
        prompt="${prompts[$((RANDOM % ${#prompts[@]}))]}"
        output="music/music_26/music_${TIMESTAMP}_${i}.mp3"
        mkdir -p "music/music_26"
        log "music-2.6: ${prompt:0:50}..."
        mmx music generate --prompt "$prompt" --lyrics-optimizer --out "$output" --quiet 2>/dev/null && log "Saved: $output" || log "FAILED: music $i"
        sleep 30
    done
}

# ==== music-cover ====
gen_music_cover() {
    # music-cover needs reference audio — skip in auto-generate
    log "music-cover: skipped (requires reference audio)"
}

# ==== MiniMax-M2.7 (text) — parallel batched ====
gen_text() {
    local topics=(
        "Write a haiku about mountains"
        "Write a short limerick about a curious cat"
        "Explain quantum computing in simple terms"
        "List five benefits of meditation"
        "Write a fortune cookie message"
        "Describe the color blue to someone who has never seen"
        "What would you find at the end of a rainbow"
        "Write an example of onomatopoeia for each letter A to Z"
        "How does photosynthesis work in one sentence"
        "Name three things that are always improving"
        "Write a very short horror micro-story"
        "What time is it on the sun"
        "Create a creative excuse for being late"
        "Name colors that do not exist in the rainbow"
        "Write a haiku about code"
        "Give me a random fact"
        "Write a tongue twister"
        "Create an acronym and explain what it means"
        "Name the layers of the ocean from shallow to deep"
        "Write a one-sentence summary of the meaning of life"
    )

    mkdir -p "text/MiniMax_M27"

    # Split topics into 4 parallel batches
    local batch1=("${topics[0]}" "${topics[1]}" "${topics[2]}" "${topics[3]}" "${topics[4]}")
    local batch2=("${topics[5]}" "${topics[6]}" "${topics[7]}" "${topics[8]}" "${topics[9]}")
    local batch3=("${topics[10]}" "${topics[11]}" "${topics[12]}" "${topics[13]}" "${topics[14]}")
    local batch4=("${topics[15]}" "${topics[16]}" "${topics[17]}" "${topics[18]}" "${topics[19]}")


    # Run each batch in parallel
    _text_batch "batch1" "${batch1[@]}" &
    local pid1=$!
    _text_batch "batch2" "${batch2[@]}" &
    local pid2=$!
    _text_batch "batch3" "${batch3[@]}" &
    local pid3=$!
    _text_batch "batch4" "${batch4[@]}" &
    local pid4=$!


    wait $pid1 || log "text batch1 subshell exited non-zero"
    wait $pid2 || log "text batch2 subshell exited non-zero"
    wait $pid3 || log "text batch3 subshell exited non-zero"
    wait $pid4 || log "text batch4 subshell exited non-zero"
}


_text_batch() {
    local batch_name=$1
    shift
    for topic in "$@"; do
        safe=$(echo "$topic" | sed 's/[^a-zA-Z0-9]/_/g' | tr '[:upper:]' '[:lower:]' | cut -c1-25)
        output="text/MiniMax_M27/text_${TIMESTAMP}_${safe}.txt"
        log "text/M2.7 [$batch_name]: $topic"
        _raw=$(mmx text chat --message "$topic" --output json 2>/dev/null)
        printf '%s' "$_raw" | python3 -c "
import sys,json
d=json.load(sys.stdin)
for block in d.get('content',[]):
    if block.get('type')=='text':
        txt=block.get('text','').strip()
        if txt:
            print(txt)
" > "$output"
        if [ -s "$output" ]; then
            log "Saved: $output"
        else
            log "FAILED: text for $topic"
        fi
        sleep 5
    done
}

# ==== GIT PUSH via gh auth ====
git_push() {
    log "=== Git push cycle ==="
    git add -A
    if git diff --cached --quiet 2>/dev/null; then
        log "No changes to commit"
    else
        git commit -m "Auto-commit $(date '+%Y-%m-%d %H:%M')" 2>/dev/null
        TOKEN=$($GH auth token)
        git push "https://${TOKEN}@github.com/mcpe500/datasets.git" HEAD:main 2>&1 | tee -a "$LOG" || log "Push failed (will retry next cycle)"
        log "Git push complete"
    fi

    log "--- Stats ---"
    for folder in images/speech music text video; do
        count=$(find "$REPO_DIR/$folder" -type f 2>/dev/null | wc -l)
        log "  $folder: $count files"
    done
}

# ==== MAIN ====
main() {
    acquire_lock
    log "=== Gen cycle started ==="


    # Full overlap: ALL generators start at t=0 simultaneously
    gen_image_01 &
    local pid_img=$!
    gen_speech_hd &
    local pid_sp=$!
    gen_music_26 &
    local pid_mus=$!
    gen_music_cover &
    gen_text &
    local pid_txt=$!

    # Wait for media (text runs in parallel, doesn't block)
    wait $pid_img || log "image-01 subshell exited non-zero"
    wait $pid_sp || log "speech-2.8-hd subshell exited non-zero"
    wait $pid_mus || log "music-2.6 subshell exited non-zero"
    wait $pid_txt || log "text subshell exited non-zero"

    git_push

    log "=== Cycle complete ==="
}

main
