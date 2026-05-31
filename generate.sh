#!/bin/bash
set -e

REPO_DIR="/data/data/com.termux/files/home/datasets"
LOG="$REPO_DIR/generator.log"
LOCK="$REPO_DIR/.generate.lock"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
GH="/data/data/com.termux/files/usr/bin/gh"

acquire_lock() {
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

trap 'rm -rf "$LOCK" 2>/dev/null' EXIT

cd "$REPO_DIR"

# ==== lyrics (100 quota available — fast generator) ====
gen_lyrics() {
    local themes=(
        "Love and heartbreak"
        "Adventure and discovery"
        "Dreams and aspirations"
        "Nature and seasons"
        "Memories and nostalgia"
        "Hope and perseverance"
        "Joy and celebration"
        "Loss and healing"
        "Journey and travel"
        "Home and belonging"
        "Freedom and choices"
        "Time and memory"
        "Stars and the cosmos"
        "Rain and renewal"
        "Strength and resilience"
 "Music and rhythm"
        "Stories we tell"
        "Light and darkness"
        "Birds and flight"
        "Mountains and peaks"
    )

    mkdir -p "lyrics"

    local batch1=("${themes[0]}" "${themes[1]}" "${themes[2]}" "${themes[3]}" "${themes[4]}" "${themes[5]}" "${themes[6]}" "${themes[7]}" "${themes[8]}" "${themes[9]}")
    local batch2=("${themes[10]}" "${themes[11]}" "${themes[12]}" "${themes[13]}" "${themes[14]}" "${themes[15]}" "${themes[16]}" "${themes[17]}" "${themes[18]}" "${themes[19]}")

    _lyrics_batch "batch1" "${batch1[@]}" &
    local pid1=$!
    _lyrics_batch "batch2" "${batch2[@]}" &
    local pid2=$!

    wait $pid1 || log "lyrics batch1 subshell exited non-zero"
    wait $pid2 || log "lyrics batch2 subshell exited non-zero"
}

_lyrics_batch() {
    local batch_name=$1
    shift
    for theme in "$@"; do
        safe=$(echo "$theme" | sed 's/[^a-zA-Z0-9]/_/g' | tr '[:upper:]' '[:lower:]' | cut -c1-30)
        output="lyrics/lyrics_${TIMESTAMP}_${safe}.txt"
        log "lyrics [$batch_name]: $theme"

        success=0
        for attempt in 1 2; do
            _raw=$(mmx text chat --message "Write a short song lyric (4 verses, chorus) about $theme" --output json 2>/dev/null)
            if printf '%s' "$_raw" | python3 -c "
import sys,json
d=json.load(sys.stdin)
for block in d.get('content',[]):
    if block.get('type')=='text':
        txt=block.get('text','').strip()
        if txt:
            print(txt)
" > "$output" 2>/dev/null && [ -s "$output" ]; then
                success=1
                break
            fi
            if [ $attempt -lt 2 ]; then
                log "lyrics [$batch_name] retry failed, waiting 3s..."
                sleep 3
            fi
        done
        if [ $success -eq 1 ]; then
            log "Saved: $output"
        else
            log "FAILED: lyrics for $theme"
        fi
        sleep 3
    done
}

# ==== MiniMax-M2.7 (text) — 150 topics, 15 parallel batches, 1 retry ====
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
        "What is the capital of Australia"
        "Describe the taste of an orange to someone who has never tasted one"
        "Write a haiku about rain"
        "Name five things you can see in the sky"
        "What year did World War II end"
        "Write a tongue twister about a sheep"
        "Name three programming languages"
        "What is the largest planet in our solar system"
        "Write a fortune cookie message about the future"
        "Name the primary colors"
        "What is the square root of 144"
        "Write a haiku about the ocean"
        "Name five types of fruit"
        "What is the chemical symbol for gold"
        "Write a very short joke"
        "Name three things that are round"
        "What is the fastest land animal"
        "Write a limerick about a dog"
        "Name the days of the week"
        "What is the boiling point of water in Celsius"
        "Write a haiku about stars"
        "Name three ocean animals"
        "What is the largest ocean"
        "Write a short riddle"
        "Name five words that start with the letter S"
        "What is the speed of light"
        "Write a fortune cookie message about luck"
        "Name three things you find in a kitchen"
        "What is the tallest mountain in the world"
        "Write a haiku about the moon"
        "Name three types of music"
        "What is the smallest country in the world"
        "What is the largest mammal"
        "Name four cardinal directions"
        "Write a haiku about autumn leaves"
        "What is the hardest natural substance"
        "Name three famous inventors"
        "Write a tongue twister about a tiger"
        "What is the currency of Japan"
        "Name five types of dinosaurs"
        "Write a fortune cookie message about friendship"
        "What is the tallest building in the world"
        "Name three things that glow in the dark"
        "Write a limerick about a monkey"
        "What is the freezing point of water in Celsius"
        "Name the seven continents"
        "Write a haiku about springtime"
        "What is the most spoken language in the world"
        "Name three things made of metal"
        "Write a short riddle with an apple as the answer"
        "What is the speed of sound"
        "Name four seasons of the year"
        "Write a fortune cookie message about courage"
        "What is the square root of 81"
        "Name three types of clouds"
        "Write a haiku about winter snow"
        "What is the capital of France"
        "Name five wild animals"
        "Write a tongue twister about a fish"
        "What is the largest bird"
        "Name three things you can ride"
        "Write a limerick about a mouse"
        "What is the boiling point of milk"
        "Name the planets in order from the sun"
        "Write a fortune cookie message about wisdom"
        "What is the fastest flying bird"
        "Name three things that are soft"
        "Write a haiku about a butterfly"
        "What is the capital of Brazil"
        "Name four ocean zones"
        "Write a short riddle with a key as the answer"
        "What is the deepest ocean trench"
        "Name three ancient civilizations"
        "Write a tongue twister about a frog"
        "What is the tallest tree species"
        "Name five colors of the rainbow"
        "Write a fortune cookie message about perseverance"
        "What is the loudest animal on Earth"
        "Name three things that spark"
        "Write a limerick about a bird"
        "What is the brightest star in the night sky"
        "Name four types of precipitation"
        "Write a haiku about the sunrise"
        "What is the deepest lake in the world"
        "Name three things that hum"
        "What is the capital of Canada"
        "Write a fortune cookie message about patience"
        "Name three famous painters"
        "Write a haiku about a rainbow"
        "What is the fastest sea creature"
        "Name four types of clouds"
        "Write a tongue twister about a monkey"
        "What is the most abundant gas in Earth's atmosphere"
        "Name three things that are sticky"
        "Write a limerick about a fish"
        "What is the capital of Germany"
        "Name five types of trees"
        "Write a fortune cookie message about hope"
        "What is the longest river in the world"
        "Name three things that float"
        "Write a haiku about the sunset"
        "What is the hottest planet in our solar system"
        "Name four ancient wonders of the world"
        "Write a short riddle with a candle as the answer"
        "What is the largest continent"
        "Name three things that are transparent"
        "Write a tongue twister about a rabbit"
        "What is the capital of Italy"
        "Name five types of flowers"
        "Write a fortune cookie message about dreams"
        "What is the deepest part of the ocean"
        "Name three things that are magnetic"
        "Write a haiku about a garden"
        "What is the tallest animal in the world"
        "Name four types of precipitation"
        "Write a limerick about a duck"
        "What is the capital of Spain"
        "Name three things that are made of wood"
        "Write a fortune cookie message about kindness"
        "What is the largest desert in the world"
        "Name three things that are cold"
        "Write a haiku about a forest"
        "What is the most visited country in the world"
        "Name four types of birds"
        "Write a short riddle with a book as the answer"
        "What is the longest wall in the world"
        "Name three things that grow"
        "Write a tongue twister about a duck"
        "What is the capital of China"
        "Name five types of music"
        "Write a fortune cookie message about love"
        "What is the largest volcano in the world"
        "Name three things that are loud"
        "Write a haiku about the wind"
        "What is the tallest mountain in Africa"
        "Name four types of weather"
        "Write a limerick about a chicken"
        "What is the capital of Russia"
        "Name three things that are heavy"
        "Write a fortune cookie message about success"
        "What is the largest island in the world"
        "Name three things that are tall"
        "Write a haiku about a river"
        "What is the most populated city in the world"
    )

    mkdir -p "text/MiniMax_M27"

    local batch1=("${topics[0]}" "${topics[1]}" "${topics[2]}" "${topics[3]}" "${topics[4]}" "${topics[5]}" "${topics[6]}" "${topics[7]}" "${topics[8]}" "${topics[9]}")
    local batch2=("${topics[10]}" "${topics[11]}" "${topics[12]}" "${topics[13]}" "${topics[14]}" "${topics[15]}" "${topics[16]}" "${topics[17]}" "${topics[18]}" "${topics[19]}")
    local batch3=("${topics[20]}" "${topics[21]}" "${topics[22]}" "${topics[23]}" "${topics[24]}" "${topics[25]}" "${topics[26]}" "${topics[27]}" "${topics[28]}" "${topics[29]}")
    local batch4=("${topics[30]}" "${topics[31]}" "${topics[32]}" "${topics[33]}" "${topics[34]}" "${topics[35]}" "${topics[36]}" "${topics[37]}" "${topics[38]}" "${topics[39]}")
    local batch5=("${topics[40]}" "${topics[41]}" "${topics[42]}" "${topics[43]}" "${topics[44]}" "${topics[45]}" "${topics[46]}" "${topics[47]}" "${topics[48]}" "${topics[49]}")
    local batch6=("${topics[50]}" "${topics[51]}" "${topics[52]}" "${topics[53]}" "${topics[54]}" "${topics[55]}" "${topics[56]}" "${topics[57]}" "${topics[58]}" "${topics[59]}")
    local batch7=("${topics[60]}" "${topics[61]}" "${topics[62]}" "${topics[63]}" "${topics[64]}" "${topics[65]}" "${topics[66]}" "${topics[67]}" "${topics[68]}" "${topics[69]}")
    local batch8=("${topics[70]}" "${topics[71]}" "${topics[72]}" "${topics[73]}" "${topics[74]}" "${topics[75]}" "${topics[76]}" "${topics[77]}" "${topics[78]}" "${topics[79]}")
    local batch9=("${topics[80]}" "${topics[81]}" "${topics[82]}" "${topics[83]}" "${topics[84]}" "${topics[85]}" "${topics[86]}" "${topics[87]}" "${topics[88]}" "${topics[89]}")
    local batch10=("${topics[90]}" "${topics[91]}" "${topics[92]}" "${topics[93]}" "${topics[94]}" "${topics[95]}" "${topics[96]}" "${topics[97]}" "${topics[98]}" "${topics[99]}")
    local batch11=("${topics[100]}" "${topics[101]}" "${topics[102]}" "${topics[103]}" "${topics[104]}" "${topics[105]}" "${topics[106]}" "${topics[107]}" "${topics[108]}" "${topics[109]}")
    local batch12=("${topics[110]}" "${topics[111]}" "${topics[112]}" "${topics[113]}" "${topics[114]}" "${topics[115]}" "${topics[116]}" "${topics[117]}" "${topics[118]}" "${topics[119]}")
    local batch13=("${topics[120]}" "${topics[121]}" "${topics[122]}" "${topics[123]}" "${topics[124]}" "${topics[125]}" "${topics[126]}" "${topics[127]}" "${topics[128]}" "${topics[129]}")
    local batch14=("${topics[130]}" "${topics[131]}" "${topics[132]}" "${topics[133]}" "${topics[134]}" "${topics[135]}" "${topics[136]}" "${topics[137]}" "${topics[138]}" "${topics[139]}")
    local batch15=("${topics[140]}" "${topics[141]}" "${topics[142]}" "${topics[143]}" "${topics[144]}" "${topics[145]}" "${topics[146]}" "${topics[147]}" "${topics[148]}" "${topics[149]}")

    _text_batch "batch1" "${batch1[@]}" &
    _text_batch "batch2" "${batch2[@]}" &
    _text_batch "batch3" "${batch3[@]}" &
    _text_batch "batch4" "${batch4[@]}" &
    _text_batch "batch5" "${batch5[@]}" &
    _text_batch "batch6" "${batch6[@]}" &
    _text_batch "batch7" "${batch7[@]}" &
    _text_batch "batch8" "${batch8[@]}" &
    _text_batch "batch9" "${batch9[@]}" &
    _text_batch "batch10" "${batch10[@]}" &
    _text_batch "batch11" "${batch11[@]}" &
    _text_batch "batch12" "${batch12[@]}" &
    _text_batch "batch13" "${batch13[@]}" &
    _text_batch "batch14" "${batch14[@]}" &
    _text_batch "batch15" "${batch15[@]}" &

    for pid in $(jobs -p); do
        wait $pid || log "text batch subshell exited non-zero"
    done
}

# _text_batch: handles one batch of topics with 1 retry on failure
_text_batch() {
    local batch_name=$1
    shift
    for topic in "$@"; do
        safe=$(echo "$topic" | sed 's/[^a-zA-Z0-9]/_/g' | tr '[:upper:]' '[:lower:]' | cut -c1-40)
        output="text/MiniMax_M27/text_${TIMESTAMP}_${safe}.txt"
        log "text/M2.7 [$batch_name]: $topic"

        success=0
        for attempt in 1 2; do
            _raw=$(mmx text chat --message "$topic" --output json 2>/dev/null)
            if printf '%s' "$_raw" | python3 -c "
import sys,json
d=json.load(sys.stdin)
for block in d.get('content',[]):
    if block.get('type')=='text':
        txt=block.get('text','').strip()
        if txt:
            print(txt)
" > "$output" 2>/dev/null && [ -s "$output" ]; then
                success=1
                break
            fi
            if [ $attempt -lt 2 ]; then
                log "text [$batch_name] retry failed, waiting 3s..."
                sleep 3
            fi
        done
        if [ $success -eq 1 ]; then
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
        git push "https://${TOKEN}@github.com/mcpe500/datasets.git" HEAD:main >> "$LOG" 2>&1 || log "Push failed (will retry next cycle)"
        log "Git push complete"
    fi

    log "--- Stats ---"
    for folder in images/speech music lyrics text video; do
        count=$(find "$REPO_DIR/$folder" -type f 2>/dev/null | wc -l)
        log "  $folder: $count files"
    done
}

# ==== MAIN ====
main() {
    acquire_lock
    log "=== Gen cycle started ==="

    # Full overlap: lyrics + text start simultaneously
    gen_lyrics &
    local pid_lyr=$!
    gen_text &
    local pid_txt=$!

    wait $pid_lyr || log "lyrics subshell exited non-zero"
    wait $pid_txt || log "text subshell exited non-zero"

    git_push

    log "=== Cycle complete ==="
}

main
