# see https://github.com/charmbracelet/vhs
Output "/tmp/demo.gif"
Set FontFamily Menlo
Set FontSize 28
Set Width 1520
Set Height 1100
Set Margin 0
Set Padding 0

# brew install --cask font-roboto
Hide
  Type@1ms "tennis --clear --demo 3 --title 'Star Wars People' --zebra --columns name,height,homeworld,species,films --color-scale height"
  Enter
  Wait+Screen /Star/
Show
Sleep 0.2
Screenshot "/tmp/dark.png"
