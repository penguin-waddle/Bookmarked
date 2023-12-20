//
//  LoginView.swift
//  Bookmarked
//
//  Created by Vivien on 8/22/23.
//

import SwiftUI
import Firebase

struct LoginView: View {
    enum Field {
        case email, password
    }
    
    @State private var email = ""
    @State private var password = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var buttonsDisabled = true
    @State private var presentSheet = false
    @State private var logoOpacity = 0.0
    @State private var formOpacity = 0.0
    @FocusState private var focusField: Field?
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                HStack {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 35)
                    Text("Bookmarked")
                        .fontWeight(.semibold)
                        .foregroundColor(.cyan)
                        .font(.custom("Helvetica Neue", size: 40))
                }
                .padding()
                .opacity(logoOpacity)
                
                Text("Reconnect with the stories that have a special place in your heart.")
                    .font(.body)
                    .foregroundColor(.cyan)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom, 45)
                
                Group {
                    TextField("E-mail", text: $email)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .submitLabel(.next)
                        .focused($focusField, equals: .email)
                        .onSubmit {
                            focusField = .password
                        }
                        .onChange(of: email) { _ in
                            enableButtons()
                        }
                    
                    SecureField("Password", text: $password)
                        .textInputAutocapitalization(.never)
                        .submitLabel(.done)
                        .focused($focusField, equals: .password)
                        .onSubmit {
                            focusField = nil
                        }
                        .onChange(of: password) { _ in
                            enableButtons()
                        }
                }
                .opacity(formOpacity)
                .textFieldStyle(.roundedBorder)
                //.overlay {
                //    RoundedRectangle(cornerRadius: 5)
                 //       .stroke(.gray.opacity(0.5), lineWidth: 2)
                //}
                .background(Color.white.opacity(0.7))
                .cornerRadius(10)
                .padding(.horizontal)
                
                HStack {
                    Button {
                        register()
                    } label: {
                        Text("Sign Up")
                    }
                    .padding(.trailing)
                    
                    Button {
                        login()
                    } label: {
                        Text("Log In")
                    }
                    .padding(.leading)
                    
                }
                .disabled(buttonsDisabled)
                .buttonStyle(.borderedProminent)
                .tint(Color("BookColor").opacity(1.0))
                .font(.title2)
                .padding(.top)
                
            Spacer().frame(height: geometry.size.height * 0.05)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .alert(alertMessage, isPresented: $showingAlert) {
                Button("OK", role: .cancel) {}
            }
            .onAppear {
                if Auth.auth().currentUser != nil {
                    print("Login successful!")
                    presentSheet = true
                }
                withAnimation(.easeIn(duration: 1.0)) {
                    logoOpacity = 1.0
                }
                withAnimation(Animation.easeIn(duration: 0.5).delay(0.5)) {
                    formOpacity = 1.0
                }
            }
            .fullScreenCover(isPresented: $presentSheet) {
                ListView()
            }
        }
        .background(LinearGradient(gradient: Gradient(colors: [Color.white, Color.blue.opacity(0.3)]), startPoint: .top, endPoint: .bottom))
        .edgesIgnoringSafeArea(.all)
    }
    
    func enableButtons() {
        let emailIsGood = email.count >= 6 && email.contains("@")
        let passwordIsGood = password.count >= 6
        buttonsDisabled = !(emailIsGood && passwordIsGood)
    }
    
    func register() {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Sign-Up Error: \(error.localizedDescription)")
                alertMessage = "Sign-Up Error: \(error.localizedDescription)"
                showingAlert = true
            } else {
                print("Registration successful!")
                presentSheet = true
            }
        }
    }
    
    func login() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Login Error: \(error.localizedDescription)")
                alertMessage = "Login Error: \(error.localizedDescription)"
                showingAlert = true
            } else {
                print("Login successful!")
                presentSheet = true
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
