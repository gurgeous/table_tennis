Output "/tmp/demo.gif"

# see https://github.com/charmbracelet/vhs
Set BorderRadius 8
Set FontSize 14
Set FontFamily Menlo
Set Margin 10
Set Padding 0
Set Width 1000
Set Height 600
#Set WindowBar Colorful

# boot app in VHS mode
# brew install --cask font-roboto
Hide
  Type@1ms "tennis --color --demo 3 --title 'Star Wars People' --zebra --columns name,height,homeworld,species,films --color-scale height"
  Enter
  Wait+Screen /Star/
Show
Sleep 0.3
Screenshot "/tmp/dark.png"
