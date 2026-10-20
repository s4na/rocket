# frozen_string_literal: true

cask "s4na-rocket" do
  version "0.1.2"
  sha256 "ed1c512eea0c5a0dd70636a6c2ca1f5b4e06eaff33b97c43fc886207cd532b51"

  url "https://github.com/s4na/rocket/releases/download/v#{version}/Rocket-#{version}.zip"
  name "Rocket"
  desc "Application launcher with global window shortcuts"
  homepage "https://github.com/s4na/rocket"

  depends_on macos: :ventura

  app "Rocket.app", target: "Rocket (s4na).app"
end
