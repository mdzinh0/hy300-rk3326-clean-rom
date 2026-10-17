@echo off
chcp 65001 >nul
title Backup de Particoes - HY300 RK3326

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0fazer_backup.ps1"
