#!/usr/bin/env bash

# Interval between samples (in seconds) and threshold (number of intervals)
interval=60      # sample every 60 seconds
threshold=30     # if condition holds for 30 samples → 30 minutes

# Associative array to count consecutive memory-only samples for each PID
declare -A counts

while true; do
  # Capture a snapshot of all GPU processes: PID, GPU%, MEM%
  readarray -t snapshot < <(
    nvidia-smi --query-compute-apps=pid,utilization.gpu,utilization.memory \
               --format=csv,noheader,nounits
  )

  # Track which PIDs are still around this iteration
  current_pids=()

  for line in "${snapshot[@]}"; do
    # Split CSV line into variables
    IFS=',' read -r pid gpu mem <<<"$line"
    pid=${pid//[[:space:]]/}
    gpu=${gpu//[[:space:]]/}
    mem=${mem//[[:space:]]/}

    current_pids+=("$pid")

    # If GPU util is zero but memory util > 0 ⇒ increment count; else reset
    if [[ "$gpu" -eq 0 && "$mem" -gt 0 ]]; then
      counts["$pid"]=$(( ${counts["$pid"]:-0} + 1 ))
    else
      counts["$pid"]=0
    fi

    # If the count reaches the threshold, kill the process
    if [[ ${counts["$pid"]} -ge $threshold ]]; then
      echo "[$(date)] Killing PID $pid: GPU=0%, MEM=${mem}% for $((threshold * interval / 60)) min"
      kill -9 "$pid"
      counts["$pid"]=0
    fi
  done

  # Clean up counts for PIDs that have vanished
  for tracked in "${!counts[@]}"; do
    if ! printf '%s\n' "${current_pids[@]}" | grep -qx "$tracked"; then
      unset counts["$tracked"]
    fi
  done

  sleep "$interval"
done
