@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion

cd /d "%~dp0"

echo ========================================
echo  Math in Computer Science - GitHub Pages 发布
echo ========================================
echo.

where git >nul 2>nul
if errorlevel 1 (
  echo [错误] 未找到 git，请先安装 Git for Windows。
  pause
  exit /b 1
)

where node >nul 2>nul
if errorlevel 1 (
  echo [错误] 未找到 node，请先安装 Node.js。
  pause
  exit /b 1
)

if not exist "scripts\prepare-content.mjs" (
  echo [错误] 找不到 scripts\prepare-content.mjs。
  pause
  exit /b 1
)

echo [1/6] 同步 Quartz content 目录...
node scripts\prepare-content.mjs
if errorlevel 1 (
  echo [错误] content 生成失败。
  pause
  exit /b 1
)

echo.
echo [2/6] 安全检查：确认公开笔记不包含图片嵌入...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$patterns='!\[\[','!\[[^\]]*\]\('; $files=Get-ChildItem -File -Filter 'Day*.md'; $files += Get-ChildItem -Path 'content' -File -Filter 'Day*.md'; $hit=$files | Select-String -Pattern $patterns; if ($hit) { $hit | ForEach-Object { Write-Host ($_.Path + ':' + $_.LineNumber + ' ' + $_.Line) }; exit 2 }"
if errorlevel 1 (
  echo [错误] 公开版笔记里仍有图片嵌入。请先转成文字再发布。
  pause
  exit /b 1
)

echo.
echo [3/6] 安全检查：确认本地图片版不会被 Git 推送...
git check-ignore -q "本地图片版/Day1 数学地图与函数画图.md"
if errorlevel 1 (
  echo [错误] 本地图片版/ 未被 .gitignore 忽略，停止发布。
  pause
  exit /b 1
)
git check-ignore -q "assets/"
if errorlevel 1 (
  echo [错误] assets/ 未被 .gitignore 忽略，停止发布。
  pause
  exit /b 1
)

echo.
echo [4/6] 暂存公开版改动...
git add .gitignore README.md package.json package-lock.json quartz.config.yaml quartz.ts tsconfig.json scripts content "Day*.md" .github quartz globals.d.ts index.d.ts .npmrc .prettierignore .prettierrc .node-version LICENSE.txt
if errorlevel 1 (
  echo [错误] git add 失败。
  pause
  exit /b 1
)

git diff --cached --quiet
if not errorlevel 1 (
  echo 没有需要提交的改动。
  goto PUSH
)

echo.
echo [5/6] 提交改动...
for /f "tokens=1-4 delims=/-. " %%a in ("%date%") do set TODAY=%%a-%%b-%%c
for /f "tokens=1-2 delims=: " %%a in ("%time%") do set NOW=%%a%%b
set NOW=%NOW: =0%
git commit -m "Update notes for GitHub Pages %TODAY% %NOW%"
if errorlevel 1 (
  echo [错误] git commit 失败。
  pause
  exit /b 1
)

:PUSH
echo.
echo [6/6] 推送到 GitHub，触发 GitHub Pages 自动部署...
git push
if errorlevel 1 (
  echo [错误] git push 失败。请检查网络或 GitHub 登录状态。
  pause
  exit /b 1
)

echo.
echo ========================================
echo 发布已推送。GitHub Pages 通常会在几十秒后更新：
echo https://condaile191-lgtm.github.io/Math-in-Computer-Science/
echo ========================================
echo.
pause
