//
//  ContentView.swift
//  WordGarden
//
//  Created by Varun Singh on 9/21/24.
//

import SwiftUI
import AVFAudio

struct ContentView: View {
    @State private var wordsGuessed = 0
    @State private var wordsMissed = 0
    @State private var currentWordIndex = 0
    @State private var wordToGuess = ""
    @State private var revealedWord = ""
    @State private var lettersGuessed = ""
    @State private var guessesRemaining = 8
    @State private var gameStatusMessage = "How many Guesses to Uncover the Hidden Word?"
    @State private var guessedLetter = ""
    @State private var imageName = "flower8"
    @State private var playAgainHidden = true
    @State private var playAgainButonLable = "another word?"
    @State private var audioPlayer: AVAudioPlayer!
    @FocusState private var textFieldIsFocused: Bool
    
    private let wordsToGuess = ["SWIFT", "DOG", "CAT"]
    private let maximumGuesses = 8
    
    
    var body: some View {
        VStack {
            HStack {
                VStack (alignment: .leading) {
                    Text("Words Guessed: \(wordsGuessed)")
                    Text("Words Missed: \(wordsMissed)")
                }
                Spacer()
                VStack (alignment: .trailing) {
                    Text("Words to Guess: \(wordsToGuess.count - (wordsGuessed + wordsMissed))")
                    Text("Words in Game: \(wordsToGuess.count)")
                }
            }
            .padding(.horizontal)
            Spacer()
            
            Text(gameStatusMessage)
                .font(.title)
                .multilineTextAlignment(.center)
                .frame(height: 80) //keep the text in a frame, so it doesn't jump around
                .minimumScaleFactor(0.5) //If more room is required, shrink down font
                .padding()
            
            Spacer()

            Text(revealedWord)
                .font(.title)
            
            if playAgainHidden {
                HStack{
                    TextField("", text: $guessedLetter)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 30)
                        .overlay {
                            RoundedRectangle(cornerRadius: 5).stroke(.gray, lineWidth: 2)
                        }
                        .keyboardType(.asciiCapable)
                        .submitLabel(.done)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)
                        .onChange(of: guessedLetter) {
                            //trim out any characters that aren't letters. Use inverted to flip what gets let through
                            guessedLetter = guessedLetter.trimmingCharacters(in: .letters.inverted)
                            guard let lastChar = guessedLetter.last
                            else {
                                return
                            }
                            guessedLetter = String(lastChar).uppercased()
                        }
                        .onSubmit {
                            guard guessedLetter != "" else { //guard is a bouncer here. As long has the character submitted isn't the empty string, then the next view (Button) will be processed. However if not, then the parent view (HStack) is exited.
                                return
                            }
                            guessALetter()
                            updateGamePlay()
                        }
                        .focused($textFieldIsFocused)
                    
                    Button("Guess a Letter") {
                        textFieldIsFocused = false
                        guessALetter()
                        updateGamePlay()
                    }
                    .buttonStyle(.bordered)
                    .tint(.mint)
                    .disabled(guessedLetter.isEmpty)
                    .disabled(guessesRemaining == 0)
                }
            }
            
            else {
                Button(playAgainButonLable) {
                    //If all the words have been guessed
                    if currentWordIndex == wordToGuess.count {
                        //Restart the Game
                        currentWordIndex = 0
                        wordsGuessed = 0
                        wordsMissed = 0
                        playAgainButonLable = "Another Word?"
                    }
                    //reset after a word was guessed or missed
                    wordToGuess = wordsToGuess[currentWordIndex]
                    revealedWord = "_" + String(repeating: " _", count: wordsToGuess[currentWordIndex].count - 1)
                    guessesRemaining = maximumGuesses
                    //set letter guessed back to empty string
                    lettersGuessed = ""
                    guessesRemaining = maximumGuesses
                    imageName = "flower\(guessesRemaining)"
                    gameStatusMessage = "How many guesses to uncover the hidden word?"
                    playAgainHidden = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.mint)
            }
            
            Spacer()
            
            Image(imageName)
                .resizable()
                .scaledToFit()
                .animation(.easeIn(duration: 0.75), value: imageName)
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear() {
            wordToGuess = wordsToGuess[currentWordIndex]
            revealedWord = "_" + String(repeating: " _", count: wordsToGuess[currentWordIndex].count - 1)
            guessesRemaining = maximumGuesses //set when the view FIRST appears
        }
    }
    func guessALetter() {
        textFieldIsFocused = false
        lettersGuessed = lettersGuessed + guessedLetter
        revealedWord = ""
        //loop through all letters in wordToGuess
        for letter in wordToGuess {
            // check if letter in wordToGuess is in lettersGuessed (i.e. did you guess this letter already?)
            if lettersGuessed.contains(letter) {
                revealedWord = revealedWord + "\(letter) "
            } else {
                //if not, add an underscore + a blank
                revealedWord = revealedWord + "_ "
            }
        }
        revealedWord.removeLast()
    }
    
    func updateGamePlay() {
        if !wordToGuess.contains(guessedLetter) {
            guessesRemaining -= 1
            //Animate crumbling
            imageName = "wilt\(guessesRemaining)"
            playSound(soundName: "incorrect")
            //Delay change to flower image until wilt animation is done
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                imageName = "flower\(guessesRemaining)"
            }
        } else { //guess was correct
            playSound(soundName: "correct")
        }
        //When do we play another word?
        if !revealedWord.contains("_") {
            gameStatusMessage = "You Guessed it! It took you \(lettersGuessed.count) Guess\(lettersGuessed.count == 1 ? "" : "es") "
            wordsGuessed += 1
            currentWordIndex += 1
            playAgainHidden = false
            playSound(soundName: "word-guessed") //sound goes at the end
            
        } else if guessesRemaining == 0 {
            gameStatusMessage = "Better Luck Next Time. The word was \(wordsToGuess[currentWordIndex])"
            wordsMissed += 1
            currentWordIndex += 1
            playAgainHidden = false
            playSound(soundName: "word-not-guessed")
        }
        else { //Keep Guessing
            gameStatusMessage = "You've Made \(lettersGuessed.count) Guess\(lettersGuessed.count == 1 ? "" : "es")"
            
        }
        
        if currentWordIndex == wordsToGuess.count {
            playAgainButonLable = "Restart Game?"
            gameStatusMessage = gameStatusMessage + "\nYou've Tried All of the Words. Restart from the Beginning?"
        }
        
        guessedLetter = ""
    }
    
    
    func playSound(soundName: String) {
        guard let soundFile = NSDataAsset(name: soundName) else {
            print("😡 Could not read file named \(soundName)")
            return //exits out of button view
        }
        do {
            audioPlayer = try AVAudioPlayer(data: soundFile.data)
            audioPlayer.play()
        }
        catch {
            print("😡 ERROR: \(error.localizedDescription) creating audioPlayer")
        }
    }
}

#Preview {
    ContentView()
}
