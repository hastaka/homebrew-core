class Hledger < Formula
  desc "Easy plain text accounting with command-line, terminal and web UIs"
  homepage "https://hledger.org/"
  url "https://github.com/simonmichael/hledger/archive/refs/tags/1.52.1.tar.gz"
  sha256 "242ba652cb76b2ca5cab1ba7588d0c99c8b7ebb329d76785f1851f2d5e9e95f6"
  license "GPL-3.0-or-later"
  head "https://github.com/simonmichael/hledger.git", branch: "main"

  # A new version is sometimes present on Hackage before it's officially
  # released on the upstream homepage, so we check the first-party download
  # page instead.
  livecheck do
    url "https://hledger.org/install.html"
    regex(%r{href=.*?/tag/(?:hledger[._-])?v?(\d+(?:\.\d+)+)(?:#[^"' >]+?)?["' >]}i)
  end

  bottle do
    rebuild 1
    sha256 cellar: :any, arm64_tahoe:   "d7456f89d34b8bcec41264ef9b3d09add0d5ca5e92c7a90a32089937592ecd9d"
    sha256 cellar: :any, arm64_sequoia: "934357d45355fe93550aea31b6ec068eb1d3b28e4209f9dd03cbb068f50d3451"
    sha256 cellar: :any, arm64_sonoma:  "5b38264031b7a8e2f436a892273501fc5d0f50a860b1730aee58396be2d46ced"
    sha256 cellar: :any, sonoma:        "0a22f2acbc44f18f962206e4fda2303e80372040f3ef252fa54ae687e4b97970"
    sha256 cellar: :any, arm64_linux:   "215291822cb5d2e97d44e0d0534cee87788543c7bdd42a70d3a4f05070256cd5"
    sha256 cellar: :any, x86_64_linux:  "c7fb8c83b7aa5e947fb2716a11ec68e9166eee71de8bc97d9164deb23c913062"
  end

  depends_on "ghc" => :build
  depends_on "haskell-stack" => :build
  depends_on "pkgconf" => :build
  depends_on "gmp"
  depends_on "libyaml"

  uses_from_macos "libffi"
  uses_from_macos "ncurses"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    args = %W[
      --flag=libyaml:system-libyaml
      --local-bin-path=#{bin}
      --jobs=#{ENV.make_jobs}
      --no-install-ghc
      --skip-ghc-check
      --system-ghc
    ]
    if OS.linux?
      args << "--ghc-options=-pie"

      # Using global configuration to apply options to all dependencies.
      # -split-sections helps reduce installation size by over 50%.
      everything_ghc_options = %w[-split-sections]
      everything_ghc_options += %w[-fPIC -fexternal-dynamic-refs] unless Hardware::CPU.arm?
      Pathname("#{Dir.home}/.stack/config.yaml").write <<~YAML
        ghc-options:
          "$everything": #{everything_ghc_options.join(" ")}
      YAML
    end

    # Let `stack` handle its own parallelization
    ENV.deparallelize { system "stack", "install", *args }

    # Strip binaries to reduce size by ~100MB (~25%) on macOS. This has no impact on Linux. Also done upstream:
    # https://github.com/simonmichael/hledger/blob/hledger-1.52.1/.github/workflows/binaries-mac-arm64.yml#L156-L158
    system "strip", *bin.children if OS.mac?

    man1.install Utils::Gzip.compress(*Dir["hledger*/*.1"])
    info.install Utils::Gzip.compress(*Dir["hledger*/*.info"])
    bash_completion.install "hledger/shell-completion/hledger-completion.bash" => "hledger"
  end

  test do
    system bin/"hledger", "test"
    system bin/"hledger-ui", "--version"
    system bin/"hledger-web", "--test"
  end
end
