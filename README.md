# Chess setup for Mac

Sets up [En Croissant](https://encroissant.org) (a free chess app, like ChessBase) with the Stockfish engine, and imports your repertoire PGN files so you can practice them.

## 1. Install

Open **Terminal** (press Cmd + Space, type "Terminal", press Enter), paste this line and press Enter:

```bash
curl -fsSL https://raw.githubusercontent.com/JayantDeveloper/encroissant-mac-setup/main/install.sh | bash
```

It takes a minute or two. It installs:

- **En Croissant** in your Applications folder
- **Stockfish**, already connected to En Croissant
- an **Import PGN into En Croissant** shortcut on your Desktop

## 2. Get your PGN files out of ChessBase

On your Windows PC, open each repertoire in ChessBase and save or export it as a **PGN** file. Then copy the files to your Mac (USB stick, email, Google Drive, whatever's easiest).

## 3. Import them

1. Double-click **Import PGN into En Croissant** on your Desktop.
2. Drag your PGN files, or a whole folder of them, into the window that opens, then press Enter.
3. For each file, type **w** if it's a White repertoire or **b** if it's Black. If the file name already says "White" or "Black", it won't ask.

## 4. Practice

Open En Croissant, go to **Files**, double-click a repertoire and open the **Practice** tab. It quizzes you on your moves and brings back the ones you forget.

## Good to know

- **Each game is its own deck.** If a PGN file has several games in it, En Croissant shows each one separately, so you practice one game at a time.
- **Running it again is safe.** It skips anything already installed. You can import more files any time.
- **"Can't be opened" warning:** if macOS blocks En Croissant the first time, right-click it in Applications and choose **Open**.
- **Your files** live in `Documents/EnCroissant`. Each one has a small `.info` file next to it; that's how En Croissant knows it's a repertoire and which side you play.
