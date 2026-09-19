# Licensed to the .NET Foundation under one or more agreements.
# The .NET Foundation licenses this file to you under the MIT license.

if(CLR_CMAKE_TARGET_WIN32)
    list(APPEND SOURCES
        dotnet.manifest
        dotnet.rc)
endif()

list(APPEND SOURCES
    ../apphost/standalone/hostfxr_resolver.cpp
    ../corehost.cpp
)

add_executable(codenet ${SOURCES})

target_link_libraries(codenet PRIVATE hostmisc fxr_resolver)

add_sanitizer_runtime_support(codenet)

if(NOT CLR_CMAKE_TARGET_WIN32)
    disable_pax_mprotect(codenet)
endif()

install_with_stripped_symbols(codenet TARGETS corehost)
add_version_info_to_target(codenet)

if (CLR_CMAKE_HOST_APPLE)
    adhoc_sign_with_entitlements(codenet "${CLR_ENG_NATIVE_DIR}/entitlements.plist")
endif()

# CodeNet 的主程序是 `codenet`。同体再输出一份 `dotnet` 兼容副本：
#   - src/installer/pkg/sfx/installers/dotnet-host.proj 仍按 DotNetHostBinDir\dotnet$(ExeSuffix) 取宿主
#   - 下游（如 SulfurLauncher 的 CI）与既有脚本仍以 `dotnet` 调用宿主
# 两者是同一个 muxer，共享 DLL 与 SDK 布局，因此保留副本即可兼容，无需改上游工程文件。
add_custom_command(TARGET codenet POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "$<TARGET_FILE:codenet>"
            "$<TARGET_FILE_DIR:codenet>/dotnet${CMAKE_EXECUTABLE_SUFFIX}"
    COMMENT "CodeNet: emitting 'dotnet' compatibility copy of the host muxer")
