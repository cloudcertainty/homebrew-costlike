cask "costlike" do
  arch arm: "arm64", intel: "x64"

  # version and both sha256 lines are rewritten by scripts/update.sh; keep each on one line.
  version "0.11.2"
  sha256 arm:   "6d0247e292daad09f972af45d9b840518fdcb527fb82eb730be25e790d3c90b9",
         intel: "1c7cf5387ea172cfb2d5594500f31d498ea35e0f66c5b52db3645f450e65a767"

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

  # Must match the app's own LSMinimumSystemVersion (Electron's floor), or brew audit fails.
  depends_on macos: :monterey

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
end
