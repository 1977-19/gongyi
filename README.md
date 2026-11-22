# 归林

一个看起来很普通的城市环保 App。往下滑就知道了。

## 安装到 iPhone

1. 每次推送到 `main`，GitHub Actions 会自动打包一个未签名的 `GuiLin.ipa`（大约 10–20 分钟）。
2. 打开仓库的 **Releases** 页面，下载最新版本里的 `GuiLin.ipa`。
3. 用万能签（或其他签名工具）签名安装。

建议戴耳机，先点右上角的「聆听森林」再往下滑。

## 目录

- `web/index.html` 全部内容（单文件，离线可用；联网时会加载网页字体）
- `GuiLin/` iOS 外壳：WKWebView，加上震动和状态栏桥接
- `project.yml` XcodeGen 配置
- `.github/workflows/build.yml` 打包流程

## 本地预览

直接用浏览器打开 `web/index.html` 即可。
