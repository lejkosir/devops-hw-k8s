# Recording Blue/Green Demo - Multiple Terminals

## Option 1: tmux (Recommended) - Single Terminal, Multiple Panes

### Setup

1. **Create tmux session with multiple panes:**
   ```bash
   bash blue-green/tmux-demo-setup.sh
   ```

   Or manually:
   ```bash
   # Create session
   tmux new-session -d -s blue-green-demo
   
   # Split into 3 panes
   tmux split-window -v
   tmux select-pane -t 0
   tmux split-window -h
   
   # Setup pane 0 (top): Watch pods
   tmux select-pane -t 0
   tmux send-keys "watch -n 1 'kubectl get pods -n taprav-fri -l app=frontend'" C-m
   
   # Setup pane 1 (bottom-left): Monitor service
   tmux select-pane -t 1
   tmux send-keys "while true; do echo -n \"\$(date +%H:%M:%S) - \"; curl -s -o /dev/null -w \"HTTP %{http_code}\n\" https://devops-sk-07.lrk.si; sleep 1; done" C-m
   
   # Setup pane 2 (bottom-right): Commands
   tmux select-pane -t 2
   tmux send-keys "cd ~/dn03" C-m
   
   # Attach to see it
   tmux attach -t blue-green-demo
   ```

2. **Start recording:**
   ```bash
   # In a separate terminal (outside tmux)
   asciinema rec blue-green-demo.cast
   
   # Then attach to tmux session
   tmux attach -t blue-green-demo
   ```

3. **Perform demo in the command pane (bottom-right)**

4. **All panes are visible in the recording!**

### tmux shortcuts during recording:
- `Ctrl+B` then `D` - Detach (keeps session running)
- `Ctrl+B` then `Arrow keys` - Switch panes
- `Ctrl+B` then `Z` - Zoom current pane to full screen

---

## Option 2: Screen Recording - Multiple Terminal Windows

### Setup

1. **Open 3 terminal windows side by side:**
   - Window 1: `watch -n 1 'kubectl get pods -n taprav-fri -l app=frontend'`
   - Window 2: `while true; do curl -s -o /dev/null -w "%{http_code}\n" https://devops-sk-07.lrk.si; sleep 1; done`
   - Window 3: Commands (cd ~/dn03)

2. **Start screen recorder:**
   ```bash
   # Option A: SimpleScreenRecorder (GUI)
   simplescreenrecorder
   
   # Option B: ffmpeg (command line)
   ffmpeg -f x11grab -s 1920x1080 -r 30 -i :0.0 -f alsa -ac 2 -i pulse blue-green-demo.mp4
   
   # Option C: OBS Studio (GUI, if installed)
   obs
   ```

3. **Arrange terminal windows side by side and record entire screen**

4. **Perform demo in Window 3**

---

## Option 3: terminator (Terminal Multiplexer with GUI)

### Setup

1. **Install terminator:**
   ```bash
   sudo apt install terminator
   ```

2. **Create layout:**
   - Right-click in terminator → Preferences → Layouts
   - Create custom layout with 3 panes side by side
   - Save layout

3. **Load layout and record with asciinema or screen recorder**

---

## Option 4: Asciinema with Multiple Terminals (Sequential)

### If you want to use asciinema for each terminal separately:

```bash
# Terminal 1 - Watch pods
asciinema rec demo-terminal1-pods.cast
watch -n 1 'kubectl get pods -n taprav-fri -l app=frontend'

# Terminal 2 - Monitor service  
asciinema rec demo-terminal2-service.cast
while true; do curl -I https://devops-sk-07.lrk.si; sleep 1; done

# Terminal 3 - Commands
asciinema rec demo-terminal3-commands.cast
./blue-green/deploy-green.sh sha-TAG
./blue-green/switch-blue-green.sh green
```

Then combine all three recordings or reference them separately in README.

---

## Recommended Setup for Clean Demo

### Using tmux (Best Option):

1. **Start recording:**
   ```bash
   asciinema rec blue-green-demo.cast
   ```

2. **Create tmux session:**
   ```bash
   # In another terminal
   bash blue-green/tmux-demo-setup.sh
   ```

3. **In asciinema recording, attach to tmux:**
   ```bash
   tmux attach -t blue-green-demo
   ```

4. **You'll see all 3 panes in the recording:**
   - Top: Pods updating in real-time
   - Bottom-left: Service responses (HTTP codes)
   - Bottom-right: Your commands

5. **Perform demo commands in bottom-right pane**

6. **All activity visible simultaneously in one recording!**

---

## Layout Example (tmux)

```
┌─────────────────────────────────┐
│  Watch Pods (refreshing)        │
│  frontend-blue-xxx  1/1 Running │
│  frontend-green-yyy 1/1 Running │
├───────────────────┬─────────────┤
│ Service Monitor   │ Commands    │
│ 14:30:01 - HTTP 200│ ./blue-     │
│ 14:30:02 - HTTP 200│ green/      │
│ 14:30:03 - HTTP 200│ switch...   │
└───────────────────┴─────────────┘
```

This gives you a professional demo showing everything happening at once!
