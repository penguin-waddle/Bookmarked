//
//  RegistrationView.swift
//  Bookmarked
//
//  Created by Vivien on 7/10/24.
//
import SwiftUI
import Firebase

struct RegistrationView: View {
    enum Field {
        case name, username, email, password
    }
    
    @State private var name = ""
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var presentSheet = false
    @State private var formOpacity = 0.0
    @State private var usernameAvailable: Bool? = nil
    @State private var registerButtonDisabled = true
    @State private var registrationSuccessful = false
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
                
                Text("One step closer to unlocking stories.")
                    .font(.body)
                    .foregroundColor(.cyan)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom, 45)
                
                Group {
                    TextField("Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .focused($focusField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focusField = .username }
                        .onChange(of: name) { _ in enableRegisterButton() }
                    
                    HStack {
                        TextField("Username", text: $username)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .focused($focusField, equals: .username)
                            .submitLabel(.next)
                            .onSubmit { focusField = .email }
                            .onChange(of: username) { newValue in
                                if newValue.isEmpty {
                                    usernameAvailable = nil
                                } else {
                                    checkUsernameAvailability()
                                }
                                enableRegisterButton()
                            }
                        
                        if let available = usernameAvailable {
                            Image(systemName: available ? "checkmark.circle" : "xmark.circle")
                                .foregroundColor(available ? .green : .red)
                        }
                    }
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($focusField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focusField = .password }
                        .onChange(of: email) { _ in enableRegisterButton() }
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusField, equals: .password)
                        .submitLabel(.done)
                        .onSubmit { focusField = nil }
                        .onChange(of: password) { _ in enableRegisterButton() }
                }
                .background(Color.white.opacity(0.7))
                .cornerRadius(10)
                .opacity(formOpacity)
                .padding(.horizontal)
                
                Button(action: register) {
                    Text("Register")
                        .font(.title2)
                        .padding()
                        .foregroundColor(.white)
                        .background(registerButtonDisabled ? Color.gray.opacity(0.3) : Color("BookColor").opacity(1.0))
                        .cornerRadius(10)
                }
                .disabled(registerButtonDisabled)
                .padding(.horizontal)
                .alert(isPresented: $showingAlert) {
                    Alert(
                        title: Text(alertMessage),
                        dismissButton: .default(Text("OK")) {
                            if registrationSuccessful {
                                presentSheet = true
                            }
                        }
                    )
                }
                
                Spacer().frame(height: geometry.size.height * 0.05)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LinearGradient(gradient: Gradient(colors: [Color.white, Color.blue.opacity(0.3)]), startPoint: .top, endPoint: .bottom))
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                withAnimation(.easeIn(duration: 1.0)) {
                    formOpacity = 1.0
                }
            }
            .fullScreenCover(isPresented: $presentSheet) {
                MainTabView()
            }
        }
    }
    
    func enableRegisterButton() {
        let emailIsValid = email.contains("@") && email.contains(".")
        let passwordIsValid = password.count >= 6
        let usernameIsValid = !(username.isEmpty) && usernameAvailable == true
        let nameIsValid = !name.isEmpty
        
        registerButtonDisabled = !(emailIsValid && passwordIsValid && usernameIsValid && nameIsValid)
    }
    
    func checkUsernameAvailability() {
        let db = Firestore.firestore()
        let userRef = db.collection("users").whereField("username", isEqualTo: username)
        userRef.getDocuments { (querySnapshot, error) in
            if let error = error {
                alertMessage = "Error checking username: \(error.localizedDescription)"
                showingAlert = true
                usernameAvailable = false
            } else if let querySnapshot = querySnapshot, !querySnapshot.isEmpty {
                usernameAvailable = false
            } else {
                usernameAvailable = true
            }
            enableRegisterButton()
        }
    }
    
    func register() {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                alertMessage = "Sign-Up Error: \(error.localizedDescription)"
                showingAlert = true
                registrationSuccessful = false
            } else if let user = result?.user {
                let userRef = Firestore.firestore().collection("users").document(user.uid)
                let userData = [
                    "id": user.uid,
                    "name": name,
                    "username": username,
                    "email": user.email ?? "",
                    "profilePictureURL": "",
                    "bio": "",
                    "favorites": [],
                    "reviews": [],
                    "readLists": [],
                    "followers": [],
                    "following": []
                ] as [String : Any]
                userRef.setData(userData) { error in
                    if let error = error {
                        alertMessage = "Error creating account: \(error.localizedDescription)"
                        showingAlert = true
                        registrationSuccessful = false
                    } else {
                        alertMessage = "Registration successful!"
                        showingAlert = true
                        registrationSuccessful = true
                    }
                }
            }
        }
    }
}

#Preview {
    RegistrationView()
}
