#!/bin/bash
# Script to set up tmux session for blue/green demo recording
# Usage: bash tmux-demo-setup.sh

SESSION="blue-green-demo"

# Create new tmux session
tmux new-session -d -s "$SESSION"

# Split window horizontally (top/bottom)
tmux split-window -v -t "$SESSION:0"

# Split bottom pane vertically (left/right)
tmux select-pane -t "$SESSION:0.1"
tmux split-window -h -t "$SESSION:0.1"

# Now we have 3 panes:
# Pane 0 (top): Watch pods
# Pane 1 (bottom-left): Monitor service
# Pane 2 (bottom-right): Run commands

# Setup pane 0: Watch pods
tmux select-pane -t "$SESSION:0.0"
tmux send-keys "watch -n 1 'kubectl get pods -n taprav-fri -l app=frontend'" C-m

# Setup pane 1: Monitor service responses
tmux select-pane -t "$SESSION:0.1"
tmux send-keys "echo 'Monitoring service responses...'" C-m
tmux send-keys "while true; do echo -n \"\$(date +%H:%M:%S) - \"; curl -s -o /dev/null -w \"HTTP %{http_code}\n\" http://devops-sk-07.lrk.si; sleep 1; done" C-m

# Setup pane 2: Ready for commands
tmux select-pane -t "$SESSION:0.2"
tmux send-keys "cd ~/dn03 && echo 'Ready for blue/green demo commands'" C-m
tmux send-keys "echo 'Commands:'" C-m
tmux send-keys "echo '  ./blue-green/check-version.sh'" C-m
tmux send-keys "echo '  ./blue-green/deploy-green.sh sha-TAG'" C-m
tmux send-keys "echo '  ./blue-green/switch-blue-green.sh green'" C-m

# Attach to session
echo "Tmux session '$SESSION' created!"
echo "To attach: tmux attach -t $SESSION"
echo ""
echo "To start recording with asciinema:"
echo "  asciinema rec blue-green-demo.cast"
echo "  tmux attach -t $SESSION"
echo ""
echo "Press Enter to attach now, or Ctrl+C to exit"
read
tmux attach -t "$SESSION"
