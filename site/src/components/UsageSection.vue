<script setup></script>

<template>
  <section id="usage" class="section">
    <div class="shell">
      <div class="section-head">
        <div>
          <div class="label">Getting started</div>
          <h2 class="section-title">使用方式</h2>
        </div>
      </div>

      <div class="steps">
        <div>
          <div class="step-no">STEP 01</div>
          <div class="step-title">解压 macOS 完整 SDK</div>
          <pre class="code">tar xzf dotnet-codenet-osx-arm64-fixed.tar.gz
<span class="cm"># 解压后顶层目录为 dotnet11x64/</span>
export DOTNET_ROOT="$PWD/dotnet11x64"
export PATH="$DOTNET_ROOT:$PATH"</pre>
        </div>

        <div>
          <div class="step-no">STEP 02</div>
          <div class="step-title">用该 SDK 执行自包含发布</div>
          <p class="lede" style="margin-bottom: 12px">
            下游构建（例如 SulfurLauncher 的发布工作流）正是从 Release 拉取 SDK，
            设置 <span class="mono">DOTNET_ROOT</span> 后执行自包含发布，产物天然携带修复运行时。
          </p>
          <pre class="code">dotnet publish -c Release -r osx-arm64 --self-contained true</pre>
        </div>

        <div>
          <div class="step-no">STEP 03</div>
          <div class="step-title">Linux / Windows 运行时包</div>
          <p class="lede">
            Linux 与 Windows 资产是平铺的 CoreCLR + 共享框架文件，需并入已有 SDK 的
            <span class="mono">shared/Microsoft.NETCore.App/</span> 目录后使用。
          </p>
        </div>
      </div>
    </div>
  </section>
</template>