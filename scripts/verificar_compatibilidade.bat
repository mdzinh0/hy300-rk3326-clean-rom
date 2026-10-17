@echo off
chcp 65001 >nul
title Verificador de Compatibilidade - HY300 RK3326

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0verificar_compatibilidade.ps1"
