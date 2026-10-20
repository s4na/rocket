# frozen_string_literal: true

cask "s4na-rocket" do
  version "0.1.1"
  sha256 "3f449dd2cb0fcb7cac314183f43f54003b55e24a18d6bc4e9468aa9d0288e963"

  url "https://github.com/s4na/rocket/releases/download/v#{version}/Rocket-#{version}.zip"
  name "Rocket"
  desc "Application launcher with global window shortcuts"
  homepage "https://github.com/s4na/rocket"

  depends_on macos: :ventura

  app "Rocket.app", target: "Rocket (s4na).app"
end
