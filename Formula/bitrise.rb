class Bitrise < Formula
  desc "Command-line automation tool"
  homepage "https://github.com/bitrise-io/bitrise"
  url "https://github.com/bitrise-io/bitrise/archive/1.3.6.tar.gz"
  sha256 "b52d51fa0a8989ea5ecd3049868fefe3c77c6f845f063a8cd9863b8989275964"

  bottle do
    cellar :any_skip_relocation
    sha256 "c5c7c05e3619129e8c18d1e7da8dc36826626beffcd0ecceb964b21f47869cd0" => :el_capitan
    sha256 "250c3044b82a78aa64279cb80ed885d7e1dc89be35cb62631246950eb3fde19e" => :yosemite
    sha256 "43bad5377664034c51a1031fd97710ccf07b82af5e40b62675ce3b61513fb002" => :mavericks
  end

  depends_on "go" => :build
  depends_on "godep" => :build

  resource "envman" do
    url "https://github.com/bitrise-io/envman/archive/1.1.0.tar.gz"
    sha256 "5e8d92dc8d38050e9e4c037e6d02bf8ad454c74a9a55c1eaeec9df8c691c2a51"
  end

  resource "stepman" do
    url "https://github.com/bitrise-io/stepman/archive/0.9.21.tar.gz"
    sha256 "a9448ad6d139685287ebdf7f89707b5ec1d1e4206d981360050dd5675a73e987"
  end

  def install
    ENV["GOPATH"] = buildpath

    # Install bitrise
    bitrise_go_path = buildpath/"src/github.com/bitrise-io/bitrise"
    bitrise_go_path.install Dir["*"]

    cd bitrise_go_path do
      system "go", "build", "-o", bin/"bitrise"
    end

    # Install envman
    resource("envman").stage do
      envman_go_pth = buildpath/"src/github.com/bitrise-io/envman"
      envman_go_pth.install Dir["*"]

      cd envman_go_pth do
        system "godep", "go", "build", "-o", bin/"envman"
      end
    end

    # Install stepman
    resource("stepman").stage do
      stepman_go_pth = buildpath/"src/github.com/bitrise-io/stepman"
      stepman_go_pth.install Dir["*"]

      cd stepman_go_pth do
        system "godep", "go", "build", "-o", bin/"stepman"
      end
    end
  end

  test do
    (testpath/"bitrise.yml").write <<-EOS.undent
      format_version: 1.1.0
      default_step_lib_source: https://github.com/bitrise-io/bitrise-steplib.git
      workflows:
        test_wf:
          steps:
          - script:
              inputs:
              - content: printf 'Test - OK' > brew.test.file
    EOS

    # setup with --minimal flag, to skip the included `brew doctor` check
    system "#{bin}/bitrise", "setup", "--minimal"
    # run the defined test_wf workflow
    system "#{bin}/bitrise", "run", "test_wf"
    assert_equal "Test - OK", (testpath/"brew.test.file").read.chomp
  end
end
