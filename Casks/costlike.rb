cask "costlike" do
  arch arm: "arm64", intel: "x64"

  # version and both sha256 lines are rewritten by scripts/update.sh; keep each on one line.
  version "0.10.0"
  sha256 arm:   "a7d3873d2917fc1c809466d5cdec26a7e396959616310af04b8950e95ee05428",
         intel: "8051753206c92bac6bc1291e27e25e44e290111f4287f430c90848554c5e62a5"

  url "https://costlike.com/api/download/v#{version}/CostLike-#{version}-#{arch}.dmg"
  name "CostLike"
  desc "Cloud cost management for AWS, Azure, Google Cloud, Hetzner and GitHub"
  homepage "https://costlike.com/"

  # The site's update manifest: the release marked latest, never a draft or a pre-release.
  livecheck do
    url "https://costlike.com/api/updates.json"
    strategy :json do |json|
      json.dig("latest", "version")
    end
  end

  depends_on macos: :ventura

  app "CostLike.app"

  # The database lives in "costlike" (older versions: "cloud-cost"); Electron keeps its own
  # state under the product name, "CostLike". The glob covers both on a case-sensitive
  # volume; brew style sorts case-insensitively, so two entries differing only in case
  # would tie and flip between runs.
  zap trash: [
    "~/Library/Application Support/[Cc]ost[Ll]ike",
    "~/Library/Application Support/cloud-cost",
    "~/Library/Caches/com.costlike.app",
    "~/Library/Caches/com.costlike.app.ShipIt",
    "~/Library/HTTPStorages/com.costlike.app",
    "~/Library/Logs/CostLike",
    "~/Library/Preferences/com.costlike.app.plist",
    "~/Library/Saved Application State/com.costlike.app.savedState",
  ]

  # Remove once releases are signed with a Developer ID and notarized.
  caveats <<~EOS
    CostLike is not yet notarized by Apple, so macOS blocks the first launch.
    Open it once, then go to System Settings > Privacy & Security and choose
    "Open Anyway". Each new version asks once more after an upgrade.
  EOS
end
