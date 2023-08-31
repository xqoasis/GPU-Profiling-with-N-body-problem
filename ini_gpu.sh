#!/bin/bash
srun --nodes=1 --time=0:045:00 --account=mpcs52018 --partition=gpu --gres=gpu:1 --constraint=v100 --pty zsh