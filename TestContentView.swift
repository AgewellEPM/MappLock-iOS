// TestContentView.swift - Simple test view
import SwiftUI

struct TestContentView: View {
    var body: some View {
        ZStack {
            Color.blue.opacity(0.1)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 30) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)

                Text("MappLock")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("iOS Focus & Kiosk Mode")
                    .font(.title2)
                    .foregroundColor(.secondary)

                Button(action: {
                    print("Button tapped!")
                }) {
                    Text("Start Session")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 200)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.top, 40)
            }
        }
    }
}