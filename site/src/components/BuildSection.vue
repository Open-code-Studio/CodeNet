<script setup>
import { WORKFLOW, REPO } from '../data/downloads.js'
</script>

<template>
  <section id="build" class="section">
    <div class="shell">
      <div class="section-head">
        <div>
          <div class="label">Build from source</div>
          <h2 class="section-title">从源代码构建</h2>
        </div>
        <a class="label" :href="WORKFLOW" target="_blank" rel="noreferrer">CI 工作流 ↗</a>
      </div>

      <div class="steps">
        <div>
          <div class="step-no">PREPARE · macOS</div>
          <pre class="code">brew install cmake ninja icu4c</pre>
        </div>

        <div>
          <div class="step-no">BUILD · RUNTIME</div>
          <pre class="code">./build.sh -arch arm64 -os osx -c Release \
  --subset clr+libs \
  --ninja \
  /p:TargetOS=osx \
  /p:TargetArchitecture=arm64 \
  /p:Configuration=Release</pre>
        </div>

        <div>
          <div class="step-no">PACKAGE</div>
          <p class="lede" style="margin-bottom: 12px">
            构建产物分为 CoreCLR 宿主与工具、以及全部托管库两部分，打包时需要合并；
            合并后的运行时位于 <span class="mono">artifacts/package/runtime</span>，并产出运行时包与 macOS 安装包。
          </p>
          <pre class="code">artifacts/bin/coreclr/osx.&lt;Arch&gt;.Release              <span class="cm"># libcoreclr.dylib、corerun 等</span>
artifacts/bin/runtime/*-osx-Release-&lt;Arch&gt;        <span class="cm"># System.*.dll</span>
artifacts/package/runtime                          <span class="cm"># 合并后的运行时</span>

dotnet-runtime-osx-&lt;arch&gt;.tar.gz
dotnet-runtime-osx-&lt;arch&gt;.pkg                     <span class="cm"># hub.code.codenet</span></pre>
        </div>

        <div>
          <div class="step-no">NOTE</div>
          <p class="lede">
            也可使用仓库根的 <span class="mono">./dotnet.sh</span> 调用 Code.NET 自带的 dotnet CLI，
            它会隔离运行时查找（<span class="mono">DOTNET_MULTILEVEL_LOOKUP=0</span>）以保证构建确定性。
            Linux / Windows 的 job 在 push 到 main 时由
            <a class="accent" :href="WORKFLOW" target="_blank" rel="noreferrer">build-codenet.yml</a>
            自动构建并发布到同一 Release，手动触发可指定只构建某一平台。
            贡献者环境与完整说明见仓库
            <a class="accent" :href="`${REPO}/blob/main/CONTRIBUTING.md`" target="_blank" rel="noreferrer">CONTRIBUTING.md</a>。
          </p>
        </div>
      </div>
    </div>
  </section>
</template>