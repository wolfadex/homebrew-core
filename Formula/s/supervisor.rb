class Supervisor < Formula
  include Language::Python::Virtualenv

  desc "Process Control System"
  homepage "http://supervisord.org/"
  url "https://files.pythonhosted.org/packages/ce/37/517989b05849dd6eaa76c148f24517544704895830a50289cbbf53c7efb9/supervisor-4.2.5.tar.gz"
  sha256 "34761bae1a23c58192281a5115fb07fbf22c9b0133c08166beffc70fed3ebc12"
  license "BSD-3-Clause-Modification"
  head "https://github.com/Supervisor/supervisor.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_sonoma:   "8fb7b50c5f8e0efaf6230f5ca808cf83eac1e1adae1a646f0e88d4a9686facca"
    sha256 cellar: :any_skip_relocation, arm64_ventura:  "30c5d30e66ec6a8f15adf002cac89c2a5692eefa54e1ea4626e0a29d956b6c38"
    sha256 cellar: :any_skip_relocation, arm64_monterey: "30c5d30e66ec6a8f15adf002cac89c2a5692eefa54e1ea4626e0a29d956b6c38"
    sha256 cellar: :any_skip_relocation, arm64_big_sur:  "30c5d30e66ec6a8f15adf002cac89c2a5692eefa54e1ea4626e0a29d956b6c38"
    sha256 cellar: :any_skip_relocation, sonoma:         "5a968a2f4b963fb0b09504a3da64527a535308491fa8c50366db5065bb3c5159"
    sha256 cellar: :any_skip_relocation, ventura:        "21d219b124dff18019063b8cd125c4548ede2110107897c5a6adf419322c1b5b"
    sha256 cellar: :any_skip_relocation, monterey:       "21d219b124dff18019063b8cd125c4548ede2110107897c5a6adf419322c1b5b"
    sha256 cellar: :any_skip_relocation, big_sur:        "21d219b124dff18019063b8cd125c4548ede2110107897c5a6adf419322c1b5b"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "adef8866166ae6da259889ee8645fdbdbeed275b34392b0f63aed98ed067010b"
  end

  depends_on "python@3.11"

  def install
    inreplace buildpath/"supervisor/skel/sample.conf" do |s|
      s.gsub! %r{/tmp/supervisor\.sock}, var/"run/supervisor.sock"
      s.gsub! %r{/tmp/supervisord\.log}, var/"log/supervisord.log"
      s.gsub! %r{/tmp/supervisord\.pid}, var/"run/supervisord.pid"
      s.gsub!(/^;\[include\]$/, "[include]")
      s.gsub! %r{^;files = relative/directory/\*\.ini$}, "files = #{etc}/supervisor.d/*.ini"
    end

    virtualenv_install_with_resources

    etc.install buildpath/"supervisor/skel/sample.conf" => "supervisord.conf"
  end

  def post_install
    (var/"run").mkpath
    (var/"log").mkpath
    conf_warn = <<~EOS
      The default location for supervisor's config file is now:
        #{etc}/supervisord.conf
      Please move your config file to this location and restart supervisor.
    EOS
    old_conf = etc/"supervisord.ini"
    opoo conf_warn if old_conf.exist?
  end

  service do
    run [opt_bin/"supervisord", "-c", etc/"supervisord.conf", "--nodaemon"]
    keep_alive true
  end

  test do
    (testpath/"sd.ini").write <<~EOS
      [unix_http_server]
      file=supervisor.sock

      [supervisord]
      loglevel=debug

      [rpcinterface:supervisor]
      supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

      [supervisorctl]
      serverurl=unix://supervisor.sock
    EOS

    begin
      pid = fork { exec bin/"supervisord", "--nodaemon", "-c", "sd.ini" }
      sleep 1
      output = shell_output("#{bin}/supervisorctl -c sd.ini version")
      assert_match version.to_s, output
    ensure
      Process.kill "TERM", pid
    end
  end
end
