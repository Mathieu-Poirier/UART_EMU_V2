@echo off
echo Starting UART Demo via WSL...
echo.

echo If WSL is not installed, run: wsl --install
echo.

wsl bash -c "cd /mnt/c/path/to/UART_EMU_V2 && make demo && ./bin/demo"
pause
