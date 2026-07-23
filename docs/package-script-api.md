# Package Script API / 包脚本 API

This document lists the stable symbols exported by `builder/build-package.sh` into each `package.sh`.
本文档列出 `builder/build-package.sh` 向每个 `package.sh` 暴露的稳定符号。

## Call Order / 调用顺序

1. Load target and toolchain environment.
2. Source the recipe file.
3. Prepare source files if `PACMAN_ANDROID_PKG_SRCURL` is set.
4. Run `pacman_android_recipe_prepare`.
5. Apply patches.
6. Run configure, build, install, and post-install hooks.

## Hook Functions / 钩子函数

- `pacman_android_recipe_prepare`: Pre-build setup. Use this to export `PACMAN_ANDROID_SOURCE_WORKTREE`, generate files, or override defaults.
- `pacman_android_recipe_configure`: Configure stage override.
- `pacman_android_recipe_build`: Build stage override.
- `pacman_android_recipe_install`: Install into `PACMAN_ANDROID_ROOTFS_DIR`.
- `pacman_android_recipe_post_install`: Final staging hook before packaging.

## Builder Helpers / 构建辅助函数

These are the supported helpers recipes may call.
下面这些是配方可以调用的受支持辅助函数。

- `pacman_android_default_configure`: Run the default configure step.
- `pacman_android_default_build`: Run the default build step.
- `pacman_android_default_install`: Run the default install step.
- `pacman_android_default_build_worktree`: Return the build directory for the active build system.
- `pacman_android_detect_build_system`: Infer the build system from the source tree.
- `pacman_android_resolve_build_system`: Cached wrapper around build-system detection.
- `pacman_android_require_source_worktree`: Fail if no source tree is available.
- `pacman_android_build_jobs`: Return the job count used by default builds.
- `pacman_android_has_makefile`: Detect `GNUmakefile`, `Makefile`, or `makefile`.
- `pacman_android_target_cpu_family`: Meson CPU family mapping for the current target.
- `pacman_android_target_cpu`: Meson CPU mapping for the current target.
- `pacman_android_export_source_dirname`: Refresh `PACMAN_ANDROID_PKG_SOURCE_DIRNAME` from the detected source worktree.
- `pacman_android_prepare_sysroot_headers`: Merge generic NDK headers with target arch headers into a full sysroot header overlay.
- `pacman_android_prepare_kernel_headers`: Build a kernel-only header overlay from the NDK UAPI trees.
- `pacman_android_default_configure_autotools`: Default autotools configure helper.
- `pacman_android_default_configure_cmake`: Default CMake configure helper.
- `pacman_android_default_configure_meson`: Default Meson configure helper.

## Variables / 变量

### Target and Toolchain / 目标与工具链

- `PACMAN_ANDROID_TARGET`: Target key, one of `x86_64`, `i686`, `armhf`, `aarch64` / 目标键。
- `PACMAN_ANDROID_API_LEVEL`: Android API level / Android API 等级。
- `PACMAN_ROOTDIR`: Package install root inside staged filesystem / 包安装根目录。
- `PACMAN_ANDROID_PREFIX`: Install prefix, usually `/usr` / 安装前缀。
- `PACMAN_ANDROID_SYSCONFDIR`: System config directory, usually `/etc` / 系统配置目录。
- `PACMAN_ANDROID_ABI`: Android ABI name / Android ABI 名称。
- `PACMAN_ANDROID_CLANG_TRIPLE`: Clang target triple / Clang 目标三元组。
- `PACMAN_ANDROID_CARGO_TRIPLE`: Cargo target triple / Cargo 目标三元组。
- `PACMAN_ANDROID_LIBRARY_TRIPLE`: Library/sysroot target triple / 库与 sysroot 三元组。
- `PACMAN_ANDROID_PACKAGE_ARCH`: Package architecture string / 包架构字符串。
- `PACMAN_ANDROID_NDK_ROOT`: Resolved NDK root path / 已解析的 NDK 根目录。
- `PACMAN_ANDROID_TOOLCHAIN_ROOT`: LLVM toolchain root under the NDK / NDK 内 LLVM 工具链根目录。
- `PACMAN_ANDROID_SYSROOT`: Target sysroot path / 目标 sysroot。
- `PACMAN_ANDROID_SYSROOT_INCLUDE_DIR`: Generic NDK include directory / 通用 NDK 头文件目录。
- `PACMAN_ANDROID_SYSROOT_ARCH_INCLUDE_DIR`: Arch-specific NDK include directory / 架构专用 NDK 头文件目录。
- `PACMAN_ANDROID_SYSROOT_HEADERS_DIR`: Builder-generated full overlay that merges generic and arch-specific NDK headers / builder 生成的完整 NDK 头文件合并视图。
- `PACMAN_ANDROID_KERNEL_HEADERS_DIR`: Builder-generated kernel UAPI overlay for packages such as `glibc` / builder 生成的内核 UAPI 头文件视图。
- `PACMAN_ANDROID_CC`, `PACMAN_ANDROID_CXX`, `PACMAN_ANDROID_AR`, `PACMAN_ANDROID_RANLIB`, `PACMAN_ANDROID_STRIP`, `PACMAN_ANDROID_LD`, `PACMAN_ANDROID_NM`, `PACMAN_ANDROID_READELF`, `PACMAN_ANDROID_OBJCOPY`, `PACMAN_ANDROID_OBJDUMP`: Absolute paths to the toolchain binaries / 工具链二进制绝对路径。
- `PACMAN_ANDROID_COMMON_CFLAGS`: Default target C flags / 默认目标 CFLAGS。
- `PACMAN_ANDROID_COMMON_LDFLAGS`: Default target linker flags / 默认目标 LDFLAGS。
- `CC`, `CXX`, `AR`, `RANLIB`, `STRIP`, `LD`, `NM`, `READELF`, `OBJCOPY`, `OBJDUMP`, `CPPFLAGS`, `CFLAGS`, `CXXFLAGS`, `LDFLAGS`, `PATH`: Conventional build environment variables, preloaded for recipe use / 约定俗成的构建环境变量，已预先设置。

### Builder Context / 构建上下文

- `PACMAN_ANDROID_REPO_ROOT`: Repository root / 仓库根目录。
- `PACMAN_ANDROID_PACKAGE_REF`: Requested package ref such as `core/glibc` / 请求的包引用。
- `PACMAN_ANDROID_CANONICAL_PACKAGE_REF`: Normalized `repo/name` package ref / 标准化后的 `repo/name` 引用。
- `PACMAN_ANDROID_PACKAGE_COLLECTION`: Recipe collection directory such as `core-packages` / 配方集合目录。
- `PACMAN_ANDROID_PACKAGE_REPO`: Collection repo name such as `core` / 仓库名。
- `PACMAN_ANDROID_RECIPE_DIR`: Recipe directory / 配方目录。
- `PACMAN_ANDROID_RECIPE_FILE`: Recipe file path / 配方文件路径。
- `PACMAN_ANDROID_BUILD_ROOT`: Root directory for one package and target build / 单包单目标的构建根目录。
- `PACMAN_ANDROID_BUILD_DIR`: Generic build work directory / 通用构建工作目录。
- `PACMAN_ANDROID_SOURCE_DIR`: Parent directory that receives extracted source files / 源码解压父目录。
- `PACMAN_ANDROID_SOURCE_WORKTREE`: Actual source tree root / 实际源码工作树根。
- `PACMAN_ANDROID_SOURCE_ROOT`: Alias of `PACMAN_ANDROID_SOURCE_WORKTREE` / `PACMAN_ANDROID_SOURCE_WORKTREE` 的别名。
- `PACMAN_ANDROID_PKG_SOURCE_DIRNAME`: Detected top-level source directory name, populated by the builder / builder 探测得到的源码顶层目录名。
- `PACMAN_ANDROID_CMAKE_BUILD_DIR`: CMake build directory / CMake 构建目录。
- `PACMAN_ANDROID_MESON_BUILD_DIR`: Meson build directory / Meson 构建目录。
- `PACMAN_ANDROID_AUTOTOOLS_BUILD_DIR`: Autotools build directory / Autotools 构建目录。
- `PACMAN_ANDROID_MESON_CROSS_FILE`: Generated Meson cross file path / 生成的 Meson 交叉文件路径。
- `PACMAN_ANDROID_STAGE_ROOT`: Stage root directory / 暂存根目录。
- `PACMAN_ANDROID_ROOTFS_DIR`: Installed filesystem root / 安装树根目录。
- `PACMAN_ANDROID_INSTALL_ROOT`: Alias of `PACMAN_ANDROID_ROOTFS_DIR` / `PACMAN_ANDROID_ROOTFS_DIR` 的别名。
- `PACMAN_ANDROID_METADATA_DIR`: Metadata output directory / 元数据输出目录。
- `PACMAN_ANDROID_PACKAGE_DIR`: Final package output directory / 最终包输出目录。
- `PACMAN_ANDROID_DISTFILES_DIR`: Downloaded source cache directory / 源码下载缓存目录。
- `PACMAN_ANDROID_DISTDIR`: Alias of `PACMAN_ANDROID_DISTFILES_DIR` / `PACMAN_ANDROID_DISTFILES_DIR` 的别名。
- `PACMAN_ANDROID_DEPENDENCY_ROOTFS_DIR`: Isolated rootfs for local build dependencies / 本地构建依赖的隔离根文件系统。
- `PACMAN_ANDROID_STARTDIR`: Alias of the repository root / 仓库根目录别名。
- `PACMAN_ANDROID_SRCDIR`: Alias of `PACMAN_ANDROID_SOURCE_DIR` / `PACMAN_ANDROID_SOURCE_DIR` 的别名。
- `PACMAN_ANDROID_BUILDDIR`: Alias of `PACMAN_ANDROID_BUILD_DIR` / `PACMAN_ANDROID_BUILD_DIR` 的别名。
- `PACMAN_ANDROID_PKGDIR`: Alias of `PACMAN_ANDROID_ROOTFS_DIR` / `PACMAN_ANDROID_ROOTFS_DIR` 的别名。
- `PACMAN_ANDROID_BUILD_STACK`: Space-separated local build chain used for cycle detection / 用于循环检测的本地构建链。

### Recipe Metadata / 配方元数据

- `PACMAN_ANDROID_PKG_NAME`: Package name / 包名。
- `PACMAN_ANDROID_PKG_VERSION`: Upstream version / 上游版本。
- `PACMAN_ANDROID_PKG_REVERSION`: Packaging reversion / 打包修订号。
- `PACMAN_ANDROID_PKG_DESCRIPTION`: Package description / 包描述。
- `PACMAN_ANDROID_PKG_URL`: Upstream project URL / 上游项目网址。
- `PACMAN_ANDROID_PKG_BASE`: Package base name / 包基础名。
- `PACMAN_ANDROID_PKG_PACKAGER`: Packager identity / 打包者信息。
- `PACMAN_ANDROID_PKG_SRCURL`: Source archive URL / 源码归档下载地址。
- `PACMAN_ANDROID_PKG_SHA256`: Source archive SHA256 / 源码归档 SHA256。
- `PACMAN_ANDROID_PKG_SOURCE_FILENAME`: Optional source archive filename override / 可选源码文件名覆盖。
- `PACMAN_ANDROID_PKG_BUILD_SYSTEM`: Build system selector, such as `auto`, `cmake`, `meson`, `make`, `ninja`, `none` / 构建系统选择器。
- `PACMAN_ANDROID_PKG_MAKE_INSTALL_TARGET`: Install target for `make`/`autotools` / `make` 或 `autotools` 的安装目标。
- `PACMAN_ANDROID_PKG_LICENSES`: Bash array of licenses / 许可证 Bash 数组。
- `PACMAN_ANDROID_PKG_TARGETS`: Bash array of supported targets / 支持目标 Bash 数组。
- `PACMAN_ANDROID_PKG_DEPENDS`: Runtime dependency Bash array / 运行依赖 Bash 数组。
- `PACMAN_ANDROID_PKG_RUN_DEPENDS`: Input alias merged into `PACMAN_ANDROID_PKG_DEPENDS` / 合并进运行依赖的输入别名。
- `PACMAN_ANDROID_PKG_MAKE_DEPENDS`: Build dependency Bash array / 构建依赖 Bash 数组。
- `PACMAN_ANDROID_PKG_BUILD_DEPENDS`: Input alias merged into `PACMAN_ANDROID_PKG_MAKE_DEPENDS` / 合并进构建依赖的输入别名。
- `PACMAN_ANDROID_PKG_CHECK_DEPENDS`: Reserved for check/test dependencies / 预留给检查或测试依赖。
- `PACMAN_ANDROID_PKG_PROVIDES`: Bash array of provided package names / 提供项 Bash 数组。
- `PACMAN_ANDROID_PKG_CONFLICTS`: Bash array of conflicting package names / 冲突项 Bash 数组。
- `PACMAN_ANDROID_PKG_REPLACES`: Bash array of replaced package names / 替换项 Bash 数组。
- `PACMAN_ANDROID_PKG_EXTRA_CONFIGURE_ARGS`: Extra configure arguments / 额外 configure 参数。
- `PACMAN_ANDROID_PKG_EXTRA_BUILD_ARGS`: Extra build arguments / 额外 build 参数。
- `PACMAN_ANDROID_PKG_EXTRA_INSTALL_ARGS`: Extra install arguments / 额外 install 参数。

## Notes / 说明

- `PACMAN_ANDROID_PKG_SOURCE_DIRNAME` is builder-generated and should be read, not set, by recipe authors / `PACMAN_ANDROID_PKG_SOURCE_DIRNAME` 由 builder 生成，配方作者应读取而不是手工设置。
- `PACMAN_ANDROID_PKG_BUILD_DEPENDS` and `PACMAN_ANDROID_PKG_RUN_DEPENDS` are normalized into the older arrays before build steps run / 构建前会先把这两个别名归一化到旧数组中。
- Only the functions above are considered supported API; other internal shell functions may change without notice / 只有上面列出的函数算受支持 API，其他内部函数可能随时变动。
