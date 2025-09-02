#===============================================================================
# 📚 R libraries
#===============================================================================

library(DT)
library(ggplot2)
library(ggtext)
library(RColorBrewer)
library(shiny)
library(shinyjs)

#===============================================================================
# 👤️️ User interface
#===============================================================================

ui <- fluidPage(
  useShinyjs(),
  
  # Load external scripts and styles: Firebase SDK (core, auth, firestore, analytics), FirebaseUI (CSS, JavaScript), CryptoJS, FontAwesome, and custom scripts/styles
  tags$head(
    tags$title("BMI Calculator App"),
    tags$link(rel = "icon", href = "calculator.png", type = "image/png"),
    tags$script(src = "https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js"),
    tags$script(src = "https://www.gstatic.com/firebasejs/10.12.2/firebase-auth-compat.js"),
    tags$script(src = "https://www.gstatic.com/firebasejs/10.12.2/firebase-firestore-compat.js"),
    tags$script(src = "https://www.gstatic.com/firebasejs/10.12.2/firebase-analytics-compat.js"),
    tags$link(rel = "stylesheet", type = "text/css", href = "https://www.gstatic.com/firebasejs/ui/6.0.1/firebase-ui-auth.css"),
    tags$script(src = "https://www.gstatic.com/firebasejs/ui/6.0.1/firebase-ui-auth.js"),
    tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/crypto-js/4.2.0/crypto-js.min.js"),
    tags$link(rel = "stylesheet", href = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css"),
    tags$script(src = "https://cdn.datatables.net/plug-ins/2.3.2/sorting/natural.js"),
    tags$script(src = "cookie-consent.js"),
    tags$script(src = "policies.js"),
    tags$script(src = "validate-decimals.js"),
    tags$script(src = "datatable-style.js"),
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")
  ),
  
  # Welcome
  div(id = "welcomePopup",
      style = "position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%);
             background-color: rgba(255, 255, 255, 0.95); padding: 40px 60px;
             border-radius: 15px; box-shadow: 0 10px 30px rgba(0,0,0,0.2);
             text-align: center; z-index: 1000; display: none; opacity: 0;
             transition: opacity 0.5s ease-in-out;",
      h2(id = "welcomeMessage", style = "color: #2F4F4F; font-weight: bold; font-size: 3em; margin: 0;")
  ),
  
  # Main container
  hidden(
    div(id = "main_ui",
        
        # Header
        div(style = "display: flex; justify-content: space-between; align-items: center;",
            div(style = "display: flex; flex-direction: column; align-items: flex-start;",
                h2("BMI Calculator App", class = "app-header",
                   style = "color: #2F4F4F; font-weight: bold; font-size: 2.5em; margin-bottom: 5px;"),
                p("Version for Adult Patients",
                  style = "color: #696969; font-size: 1.1em; margin-top: 0;")
            ),
            tags$button(
              id = "logoutButton",
              class = "btn-reject",
              icon("sign-out-alt", style = "margin-right: 10px;"),
              " Logout"
            )
        ),
        
        # Card 1: New patient entry
        div(class = "card-box",
            style = "margin-top: 20px;",
            h3(icon("user-plus"), "New patient entry", class = "card-title"),
            
            fluidRow(
              column(6,
                     textInput("patientId", "Patient ID", placeholder = "Example: BBB123456789", width = "100%")
              ),
              column(6,
                     selectInput("sex", "Sex", choices = c("Select..." = "", "Female", "Male"), width = "100%")
              )
            ),
            
            fluidRow(
              column(6,
                     tags$label("Weight (kg)", `for` = "weight"),
                     tags$input(
                       id = "weight",
                       type = "number",
                       min = "0.0",
                       step = "0.1",
                       placeholder = "Example: 70.5",
                       class = "form-control",
                       inputmode = "decimal",
                       lang = "en",
                       style = "width: 100%;"
                     )
              ),
              column(6,
                     tags$label("Height (m)", `for` = "height"),
                     tags$input(
                       id = "height",
                       type = "number",
                       min = "0.0",
                       step = "0.01",
                       placeholder = "Example: 1.72",
                       class = "form-control",
                       inputmode = "decimal",
                       lang = "en",
                       style = "width: 100%;"
                     )
              )
            ),
            
            div(style = "margin-top: 20px;",
                actionButton("saveButton",
                             tagList(icon("save", style = "margin-right: 10px;"), 
                                     "Save patient"), class = "btn-configure")
            )
            
        ),
        
        # Card 2: New patient BMI estimation
        div(class = "card-box",
            h3(icon("calculator"), "New patient BMI estimation", class = "card-title"),
            plotOutput("bmiPlot", height = "600px"),
            div(style = "margin-top: 20px;",
                downloadButton("download_report", 
                               label = span("Download report", style = "margin-left: 10px;"),
                               class = "btn-configure")
            )
        ),
        
        # Card 3: Patient records
        div(class = "card-box",
            h3(icon("users"), "Patient records", class = "card-title"),
            uiOutput("recordsNote"),
            DTOutput("recordsTable")
        )
    )
  ),
  
  # Cookie consent container
  tags$div(
    id = "cookieConsentModal", class = "modal", style = "display:none;",
    tags$div(
      class = "modal-content",
      tags$span(id = "closeCookieConsent", class = "close", HTML("&times;")),
      tags$h2("Cookie settings"),
      tags$p("We use cookies to improve your experience. Do you accept analytics and personalization cookies?"),
      tags$div(
        style = "display: flex; gap: 10px; margin-top: 15px; margin-bottom: 15px;",
        tags$button(id = "acceptCookiesBtn", class = "btn-primary", "Accept all"),
        tags$button(id = "rejectCookiesBtn", class = "btn-reject", "Reject all"),
        tags$button(id = "configureCookiesBtn", class = "btn-configure", "Configure")
      ),
      tags$div(
        id = "cookieConfigPanel", style = "display:none; margin-top: 15px;",
        tags$h3("Select which cookies to enable:"),
        tags$div(
          tags$label(
            tags$input(type = "checkbox", id = "essentialCookies", checked = TRUE, disabled = TRUE),
            " Essential cookies",
            tags$br(),
            tags$small(style = "font-weight: normal;", "Necessary for the proper functioning of the website.")
          )
        ),
        tags$div(
          tags$label(
            tags$input(type = "checkbox", id = "analyticsCookies"),
            " Analytics cookies",
            tags$br(),
            tags$small(style = "font-weight: normal;", "Help measure traffic and improve content.")
          )
        ),
        tags$div(
          tags$label(
            tags$input(type = "checkbox", id = "personalizationCookies"),
            " Personalization cookies",
            tags$br(),
            tags$small(style = "font-weight: normal;", "Allow remembering preferences and adjusting the user experience.")
          )
        ),
        tags$button(id = "saveCookieSettingsBtn", class = "btn-configure", "Save settings")
      )
    )
  ),
  
  # Login container
  div(id = "login_ui_wrapper",
      div(id = "login_ui",
          style = "width: 600px; max-width: 90%; margin: auto; padding: 40px; text-align: center;",
          h3(icon("calculator", style = "margin-right: 10px;"), "BMI Calculator App",
             style = "color: #2F4F4F; font-weight: bold; font-size: 2em; margin-bottom: 5px;"),
          p("Version for Adult Patients",
            style = "color: #696969; font-size: 1em; margin-top: 0; margin-bottom: 20px;"),
          tags$div(id = "firebaseui-auth-container"),
          
          tags$div(
            id = "email_verification_notice",
            style = "display:none; color: #e23748; font-weight: bold; margin-top: 20px;",
            tags$span(
              icon("exclamation-triangle", style = "margin-right: 10px;"),
              HTML("A verification email has been sent.<br>Please check your email inbox or spam folder.")
            )
          ),
          tags$button(
            id = "reload_after_verification_button",
            class = "btn-login",
            style = "display:none; margin-top: 20px;",
            "DONE"
          ),
          
          # Encryption password prompt
          tags$div(
            id = "encryption_key_prompt",
            style = "display:none; color: #e23748; font-weight: bold; margin-top: 20px;",
            tags$span(
              icon("key", style = "margin-right: 10px;"),
              HTML("Enter your personal encryption password.<br>Please read the important information below.")
            ),
            tags$input(
              id = "encryption_key_input",
              type = "password",
              class = "form-control",
              style = "margin-top: 20px; color: black; font-weight: normal;
              width: 40%; display: block; margin-left: auto; margin-right: auto;"
            ),
            tags$div(
              style = "margin-top: 5px;",
              tags$span(
                tags$input(type = "checkbox", id = "toggle_password_visibility"),
                tags$label(`for` = "toggle_password_visibility", 
                           style = "color: black; font-weight: normal; margin-left: 10px;", 
                           "Show password")
              )
            ),
            tags$button(
              id = "confirm_key_button",
              class = "btn-login",
              style = "margin-top: 20px;",
              "NEXT"
            )
          ),
          
          # Important information
          tags$div(class = "login-info",
                   tags$h5(icon("info-circle", style = "margin-right: 10px;"), "Important information"),
                   tags$p(
                     icon("envelope", style = "margin-right: 10px;"), tags$strong(" Sign in with email:"),
                     " Choose this option if you wish to use the BMI Calculator App regularly and securely store your patient records in Firebase, a cloud platform provided by Google. 
                     To create an account with your email, follow the steps below."
                   ),
                   tags$ul(
                     style = "text-align: justify; padding-left: 1.2em;",
                     tags$li(
                       tags$strong("Step 1: "), 
                       "Access the BMI Calculator App, click ”Sign in with email”, enter a valid email address, a username, and a ",
                       tags$strong("login password"),
                       " (from 8 to 20 characters, including at least one uppercase letter, one lowercase letter, one number, and one special character), then click ”Save”. ",
                       tags$strong("This password is recoverable.")
                     ),
                     tags$li(
                       tags$strong("Step 2: "),
                       "Check your email inbox or spam folder to verify your email address."
                     ),
                     tags$li(
                       tags$strong("Step 3: "),
                       "Return to the BMI Calculator App, click ”Done” and then ”Sign in with email”, enter your verified email address and login password, then click ”Sign in”."
                     ),
                     tags$li(
                       tags$strong("Step 4: "),
                       "Create a ",
                       tags$strong("personal encryption password"),
                       " (from 8 to 20 characters, including at least one uppercase letter, one lowercase letter, one number, and one special character), then click ”Next”. For security, this password should be different from your login password. It encrypts your patients' data so only you can access it. ",
                       tags$strong("This password is not recoverable."),
                       " If forgotten or entered incorrectly, your encrypted records stored in Firebase will not be visible."
                     )
                   ),
                   tags$p(
                     icon("user", style = "margin-right: 10px;"), tags$strong(" Continue as guest:"),
                     " Choose this option if you only want to try the BMI Calculator App without registering with an email. 
                     Data recorded as a guest isn't encrypted, and the anonymous guest account will be automatically deleted after up to 30 days."
                   ),
                   tags$p(
                     icon("headset", style = "margin-right: 10px;"), tags$strong(" Technical support and help:"),
                     " If you run into any technical issues, have questions about the app, or wish for your account and all associated data to be permanently deleted from Firebase, please ",
                     tags$a(href = "https://raulhilenophd-nextlevelstatsandapps4u.netlify.app/", target = "_blank", "contact the app owner here."),
                     " You'll get a response as soon as possible."
                   )
          )
          ,
          
          # Legal footer
          tags$div(
            class = "legal-footer",
            style = "margin-top: 30px; font-size: 14px; color: #555; text-align: center;",
            tags$a(href = "#", id = "legalNoticeLink", style = "margin: 0 8px;", "Legal notice"),
            tags$text("|"),
            tags$a(href = "#", id = "privacyPolicyLink", style = "margin: 0 8px;", "Privacy policy"),
            tags$text("|"),
            tags$a(href = "#", id = "cookiePolicyLink", style = "margin: 0 8px;", "Cookie policy"),
            tags$div(style = "margin-top: 10px;",
                     "© 2025 Raúl Hileno González. All rights reserved."
            )
          ),
          
          # Legal notice
          tags$div(
            id = "legalNoticeModal",
            class = "modal",
            style = "display:none;",
            tags$div(
              class = "modal-content",
              tags$span(id = "closeLegalNotice", class = "close", "×"),
              tags$h3("Legal notice", style = "text-align: justify;"),
              
              tags$hr(),
              tags$h4(strong("1. Owner information"), style = "text-align: justify;"),
              tags$p(
                style = "text-align: justify;",
                "In compliance with current regulations, users are informed of the following data:"
              ),
              tags$ul(
                style = "text-align: justify; margin-left: 0; padding-left: 1.2em;",
                tags$li(tags$strong("Name:"), " Raúl Hileno González"),
                tags$li(tags$strong("NIF:"), " 46803506R"),
                tags$li(tags$strong("Address:"), " Carrer d'en Xanxo, 41, 25110, Alpicat (Lleida)"),
                tags$li(
                  tags$strong("Email:"), " ",
                  tags$a(href = "mailto:rhileno@gmail.com", "rhileno@gmail.com")
                ),
                tags$li(
                  tags$strong("Website:"), " ",
                  tags$a(
                    href = "https://raulhilenophd-nextlevelstatsandapps4u.netlify.app/es.html#",
                    target = "_blank",
                    "https://raulhilenophd-nextlevelstatsandapps4u.netlify.app"
                  )
                )
              ),
              tags$hr(),
              tags$h4(strong("2. Purpose of the Shiny app"), style = "text-align: justify;"),
              tags$p(
                style = "text-align: justify;",
                "  This Shiny app, called BMI Calculator App - Version for Adult Patients, is designed to calculate the body mass index (BMI) of adult patients based on their height and weight.
                It allows users to enter new patient data, securely store encrypted records in a Firebase database, and generate BMI visualizations."
              ),
              tags$hr(),
              tags$h4(strong("3. Terms of use"), style = "text-align: justify;"),
              tags$p(
                style = "text-align: justify;",
                "By accessing and using this Shiny app, users agree to comply with and be bound by these terms of use and the privacy policy. 
                The app and its contents are provided for personal, non-commercial use only. Users agree not to use the app for any unlawful purposes or in ways that infringe on the rights of others. 
                The owner reserves the right to suspend or terminate access to the app in case of misuse or violation of these terms. 
                Continued use of the app implies acceptance of any updates or changes made to these terms of use."
              ),
              tags$hr(),
              tags$h4(strong("4. Liability"), style = "text-align: justify;"),
              tags$p(
                style = "text-align: justify;",
                "Although security measures have been taken to ensure the proper functioning of the Shiny app, the total absence of technical errors or service interruptions cannot be guaranteed."
              )
            )
          ),
          
          # Privacy policy
          tags$div(
            id = "privacyPolicyModal",
            class = "modal",
            style = "display:none;",
            tags$div(
              class = "modal-content",
              tags$span(id = "closePrivacyPolicy", class = "close", "×"),
              tags$h3("Privacy policy", style = "text-align: justify;"),
              
              tags$hr(),
              tags$h4(strong("1. Data controller"), style = "text-align: justify;"),
              tags$p(
                style = "text-align: justify;",
                "Raúl Hileno González, with NIF 46803506R, is the owner and developer of this Shiny app, and acts as the data controller responsible for processing personal information collected through it."
              ),
              tags$hr(),
              tags$h4(strong("2. Purpose of data processing"), style = "text-align: justify;"),
              tags$p(
                style = "text-align: justify;",
                "This Shiny app registers users’ email addresses when they create a personal account using the “Sign in with email” option. 
                These email addresses, along with encrypted patient data, are securely stored in Firebase, a cloud platform provided by Google. 
                Specifically, email addresses are managed through Firebase Authentication, while patient data is encrypted on the client side before being stored in the Firebase Firestore Database. 
                Login passwords are not stored but can be reset via Firebase upon users’ request.
                Personal encryption passwords—used to encrypt patient data before uploading to Firebase and to decrypt it within the BMI Calculator App when restarted—are never stored or recoverable. 
                Users are solely responsible for remembering their encryption password. 
                All information collected in Firebase is used exclusively for the operation of this Shiny app, is never shared with third parties, and is not used for commercial purposes. 
                Users who choose the “Continue as guest” option do not register with an email. Data recorded as a guest isn't encrypted, and the anonymous guest account will be automatically deleted after up to 30 days."
              ),
              tags$hr(),
              tags$h4(strong("3. User rights"), style = "text-align: justify;"),
              tags$p(
                style = "text-align: justify;",
                "In accordance with the General Data Protection Regulation (GDPR), users may request access to, rectification or deletion of, or objection to the processing of their personal data by sending a request ",
                tags$a(href = "https://raulhilenophd-nextlevelstatsandapps4u.netlify.app/es.html", target = "_blank", "here"),
                " to the owner of this Shiny app."
              ),
              tags$hr(),
              tags$h4(strong("4. Data security"), style = "text-align: justify;"),
              tags$p(
                style = "text-align: justify;",
                "This Shiny app is hosted on shinyapps.io and connected to Firebase for authentication and remote data storage.
                Both services implement their own security measures to safeguard data integrity and confidentiality.
                Although precautions are taken to protect user data, absolute protection against unauthorized access (e.g., hacking) cannot be guaranteed.
                Users should be aware that transmitting information over the Internet always carries some risk."
              )
            )
          ),
          
          # Cookie policy
          tags$div(
            id = "cookiePolicyModal",
            class = "modal",
            style = "display:none;",
            tags$div(
              class = "modal-content",
              tags$span(id = "closeCookiePolicy", class = "close", "×"),
              tags$h3("Cookie policy", style = "text-align: justify;"),
              
              tags$hr(),
              tags$h4(strong("1. Introduction"), style = "text-align: justify;"),
              tags$p(
                style = "text-align: justify;",
                "This Shiny app uses cookies to improve the browsing experience and anonymously analyze traffic."
              ),
              
              tags$hr(),
              tags$h4(strong("2. What are cookies?"), style = "text-align: justify;"),
              tags$p(
                style = "text-align: justify;",
                "Cookies are small files stored on the user's device that help improve the website's performance."
              ),
              
              tags$hr(),
              tags$h4(strong("3. Types of cookies used"), style = "text-align: justify;"),
              tags$ul(
                style = "text-align: justify; margin-left: 0; padding-left: 1.2em;",
                tags$li(tags$strong("Essential cookies:"), " necessary for the app's proper functioning and cannot be disabled."),
                tags$li(tags$strong("Analytics cookies:"), " help measure traffic and improve content, used with Firebase and Google Analytics."),
                tags$li(tags$strong("Personalization cookies:"), " allow remembering preferences and adjusting the user experience.")
              ),
              
              tags$hr(),
              tags$h4(strong("4. Cookie management"), style = "text-align: justify;"),
              tags$p(
                style = "text-align: justify;",
                "When first accessing this Shiny app, a notice will appear to accept or decline the use of cookies. ",
                "Later, if you want to delete or modify them, this can be done from your browser settings."
              )
            )
          )
          
      )
  ),
  
  # Firebase configuration scripts
  tags$script(src = "firebase-config.js"),
  tags$script(src = "firebase-auth.js")
)

#===============================================================================
# 🧠 Server logic
#===============================================================================

server <- function(input, output, session) {
  
  #=============================================================================
  # 🔐 Authentication and session management
  #=============================================================================
  
  # Observe cookie consent
  observeEvent(input$cookieConsent, {
    if (input$cookieConsent == "accepted") {
      print("User accepted cookies")
    } else if (input$cookieConsent == "rejected") {
      print("User rejected cookies")
    }
  })
  
  # Show main UI after successful login
  observeEvent(input$userLoggedIn, {
    hide("login_ui_wrapper")
    show("main_ui")
    showNotification(paste("Logged in as:", input$userEmail), type = "message", duration = 5)
  })
  
  #=============================================================================
  # 📦 Reactive variables for storing patient data
  #=============================================================================
  
  # Store all patient records retrieved from Firebase
  patientData <- reactiveVal(data.frame())
  
  # Store the last patient entry to highlight it in the BMI plot
  lastRecordToPlot <- reactiveVal(NULL)
  
  # Store the last patient entry in the data table for report generation
  lastRecordTable <- reactiveVal(NULL)
  
  #=============================================================================
  # 🔄 Process and transform patient data from Firebase
  #=============================================================================
  
  bmi_zone <- function(bmi) {
    if (is.na(bmi)) return(NA)
    else if (bmi < 18.5) return("Underweight")
    else if (bmi < 25) return("Normal")
    else if (bmi < 30) return("Overweight")
    else if (bmi < 35) return("Obesity I")
    else if (bmi < 40) return("Obesity II")
    else return("Obesity III")
  }
  
  observeEvent(input$userData, {
    data <- input$userData
    
    if (is.null(data) || length(data) == 0) {
      patientData(data.frame())
      lastRecordToPlot(NULL)
      return()
    }
    
    tryCatch({
      n_fields <- 6
      mat <- matrix(unlist(data), ncol = n_fields, byrow = TRUE)
      colnames(mat) <- c("firestore_id", "patientId", "sex", "weight", "height", "timestamp")
      df <- as.data.frame(mat, stringsAsFactors = FALSE)
      df$firestore_id <- as.character(df$firestore_id)
      df$patientId <- as.character(df$patientId)
      df$sex <- as.character(df$sex)
      df$weight <- as.numeric(df$weight)
      df$height <- as.numeric(df$height)
      df$timestamp <- as.numeric(df$timestamp)
      df$bmi <- ifelse(is.na(df$height) | df$height == 0, NA, round(df$weight / (df$height^2), 2))
      df$bmi_zone <- sapply(df$bmi, bmi_zone)
      df$date <- format(as.POSIXct(df$timestamp / 1000, origin = "1970-01-01"), "%Y-%m-%d %H:%M:%S")
      df <- df[order(df$timestamp, decreasing = TRUE), ]
      rownames(df) <- NULL
      patientData(df)
      
    }, error = function(e) {
      showNotification(paste("Error processing data:", e$message), type = "error", duration = 5)
      patientData(data.frame())
      lastRecordToPlot(NULL)
    })
  })
  
  #=============================================================================
  # 💾 Save new patient entry data to Firebase
  #=============================================================================
  
  observeEvent(input$saveButton, {
    patient_id <- trimws(input$patientId)
    sex <- input$sex
    weight <- as.numeric(input$weight)
    height <- as.numeric(input$height)
    if (patient_id == "") {
      showNotification("Patient ID is required.", type = "error")
      return()
    }
    if (!(sex %in% c("Female", "Male"))) {
      showNotification("Please select a valid sex.", type = "error")
      return()
    }
    if (is.na(weight) || weight <= 0) {
      showNotification("Please enter a valid positive weight.", type = "error")
      return()
    }
    if (is.na(height) || height <= 0) {
      showNotification("Please enter a valid positive height.", type = "error")
      return()
    }
    session$sendCustomMessage(type = "saveData", message = list(
      patientId = patient_id,
      sex = sex,
      weight = weight,
      height = height
    ))
    showNotification("Record saved successfully!", type = "message")
    updateTextInput(session, "patientId", value = "")
    updateSelectInput(session, "sex", selected = "")
    runjs("document.getElementById('weight').value = ''; document.getElementById('height').value = '';")
  })
  
  #=============================================================================
  # ✅ Append new patient entry data after Firebase confirms save
  #=============================================================================
  
  observeEvent(input$newRecordSaved, {
    newData <- input$newRecordSaved
    new_row <- data.frame(
      firestore_id = newData$firestore_id,
      patientId = newData$patientId,
      sex = newData$sex,
      weight = as.numeric(newData$weight),
      height = as.numeric(newData$height),
      timestamp = as.numeric(newData$timestamp),
      stringsAsFactors = FALSE
    )
    new_row$bmi <- ifelse(is.na(new_row$height) || new_row$height == 0, NA,
                          round(new_row$weight / (new_row$height^2), 2))
    new_row$bmi_zone <- bmi_zone(new_row$bmi)
    new_row$date <- format(as.POSIXct(new_row$timestamp / 1000, origin = "1970-01-01"), "%Y-%m-%d %H:%M:%S")
    current_data <- isolate(patientData())
    
    updated_data <- rbind(new_row, current_data)
    updated_data <- updated_data[order(updated_data$timestamp, decreasing = TRUE), ]
    rownames(updated_data) <- NULL
    
    patientData(updated_data)
    
    lastRecordToPlot(list(
      firestore_id = new_row$firestore_id,
      patientId = new_row$patientId,
      weight = new_row$weight,
      height = new_row$height
    ))
    
    lastRecordTable(new_row)
  })
  
  #=============================================================================
  # 📊 Render BMI zones plot
  #=============================================================================
  
  output$bmiPlot <- renderPlot({
    m_range <- seq(0, 2.5, by = 0.01)
    
    kg_min <- rep(0, length(m_range))
    kg_max <- rep(250, length(m_range))
    
    kg_uw <- pmin(pmax(m_range^2 * 18.5, 0), 250)
    kg_n <- pmin(pmax(m_range^2 * 24.9, 0), 250)
    kg_ow <- pmin(pmax(m_range^2 * 29.9, 0), 250)
    kg_ob1 <- pmin(pmax(m_range^2 * 34.9, 0), 250)
    kg_ob2 <- pmin(pmax(m_range^2 * 39.9, 0), 250)
    kg_ob3 <- pmin(pmax(m_range^2 * 45, 0), 250)
    
    df_zones <- data.frame(
      height = c(
        m_range, rev(m_range),
        m_range, rev(m_range),
        m_range, rev(m_range),
        m_range, rev(m_range),
        m_range, rev(m_range),
        m_range, rev(m_range)
      ),
      weight = c(
        kg_min, rev(kg_uw),
        kg_uw, rev(kg_n),
        kg_n, rev(kg_ow),
        kg_ow, rev(kg_ob1),
        kg_ob1, rev(kg_ob2),
        kg_ob2, rev(kg_max)
      ),
      zone = factor(rep(c("Underweight", "Normal", "Overweight", "Obesity I", "Obesity II", "Obesity III"),
                        each = length(m_range)*2),
                    levels = c("Underweight", "Normal", "Overweight", "Obesity I", "Obesity II", "Obesity III"))
    )
    
    zone_colors <- c(
      "Underweight" = "#add8e6",
      "Normal" = "#7ccd7c",
      "Overweight" = "#fa8072",
      "Obesity I" = "#ffa500",
      "Obesity II" = "#ff4500",
      "Obesity III" = "#cd0000"
    )
    
    x_breaks <- seq(0.1, 2.4, by = 0.1)
    y_breaks <- seq(10, 240, by = 10)
    y_axis_formatter <- function(x) { as.character(x) }
    x_axis_formatter <- function(x) { sprintf("%.2f", x) }
    
    p <- ggplot() +
      geom_polygon(data = df_zones, aes(x = height, y = weight, group = zone, fill = zone), alpha = 0.6) +
      scale_fill_manual(values = zone_colors, name = "BMI zone") +
      guides(fill = guide_legend(reverse = TRUE)) +
      coord_cartesian(xlim = c(0, 2.5), ylim = c(0, 250), expand = FALSE) +
      labs(x = "Height (m)", y = "Weight (kg)") +
      theme_classic() +
      theme(
        legend.title = element_text(size = 15),
        legend.text = element_text(size = 13),
        legend.position = "right",
        legend.key.width = unit(1, "cm"),
        legend.key.height = unit(1, "cm"),
        legend.key.spacing.y = unit(0.5, "cm"),
        axis.title.x = element_text(size = 15, margin = margin(t = 15, unit = "pt")),
        axis.title.y = element_text(size = 15, margin = margin(r = 15, unit = "pt")),
        axis.text = element_text(size = 13, color = "black"),
        axis.text.y = element_text(angle = 0, hjust = 1),
        axis.ticks = element_line(color = "black"),
        axis.ticks.length = unit(5, "pt"),
        axis.ticks.x.bottom = element_line(),
        axis.ticks.y.left = element_line(),
      ) +
      scale_x_continuous(breaks = x_breaks, labels = x_axis_formatter) +
      scale_y_continuous(breaks = y_breaks, labels = y_axis_formatter)
    
    record <- lastRecordToPlot()
    if (!is.null(record)) {
      kg_input <- as.numeric(record$weight)
      m_input <- as.numeric(record$height)
      id_input <- record$patientId
      
      if (!is.na(kg_input) && !is.na(m_input) && m_input > 0) {
        bmi_output <- sprintf("%.2f", kg_input / (m_input^2))
        label_text_markdown <- paste0("ID: ", id_input, "\nBMI: ", bmi_output, " kg/m²")
        p <- p +
          geom_point(aes(x = m_input, y = kg_input), size = 3, shape = 21,
                     color = "black", fill = "white", stroke = 1.5) +
          annotate("text", x = m_input + 0.03, y = kg_input,
                   label = label_text_markdown,
                   hjust = 0, vjust = 0.5, size = 5.0, lineheight = 1.0)
      }
    }
    p
  })
  
  #=============================================================================
  # 🧮 Render data table of patient records
  #=============================================================================
  
  output$recordsNote <- renderUI({
    df <- patientData()
    if (nrow(df) == 0) return(NULL)
    div(
      class = "alert alert-info",
      span(icon("info-circle"), style = "margin-right: 10px;"),
      "You can edit any cell by double-clicking it, except for Evaluation date and BMI.
      When you update Weight or Height, the BMI will be recalculated automatically."
    )
  })
  
  output$recordsTable <- renderDT({
    df <- patientData()
    if (nrow(df) == 0) return(NULL)
    
    df$actions <- sapply(df$firestore_id, function(id) {
      as.character(
        tags$button(
          class = "btn-reject delete_btn",
          style = "padding: 5px 10px; font-size: 12px;",
          onclick = sprintf("if(confirm('Are you sure you want to delete this record?')) { Shiny.setInputValue('delete_firestore_id', '%s', {priority: 'event'}); }", id),
          tagList(icon("trash", style = "margin-right: 10px;"), " Delete")
        )
      )
    })
    
    max_weight <- max(df$weight, na.rm = TRUE)
    max_height <- max(df$height, na.rm = TRUE)
    max_bmi    <- max(df$bmi, na.rm = TRUE)
    
    zone_colors <- c(
      "Underweight" = "#add8e6",
      "Normal" = "#7ccd7c",
      "Overweight" = "#fa8072",
      "Obesity I" = "#ffa500",
      "Obesity II" = "#ff4500",
      "Obesity III" = "#cd0000"
    )
    
    datatable(
      df[, c("patientId", "date", "sex", "weight", "height", "bmi", "bmi_zone", "actions")],
      colnames = c("Patient ID", "Evaluation date", "Sex", "Weight (kg)", "Height (m)", "BMI (kg/m²)", "BMI zone", "Actions"),
      rownames = FALSE,
      escape = FALSE,
      extensions = 'Buttons',
      plugins = 'natural',
      editable = list(
        target = "cell",
        disable = list(columns = c(1, 5, 6, 7))
      ),
      options = list(
        dom = 'Bfrtip',
        initComplete = JS("function(settings, json) {
          window.customDataTableInitComplete.call(this, settings, json);
        }"),
        headerCallback = JS("function(thead, data, start, end, display) {
          $('th', thead).css('border-top', '1px solid #5d64a3');
        }"),
        buttons = list(
          list(
            extend = 'csv',
            text = '<i class="fa fa-file-csv" style="margin-right: 5px;"></i> CSV',
            titleAttr = "Export patient records in CSV format",
            filename = 'patient_records',
            title = NULL,
            exportOptions = list(
              charset = "UTF-8",
              orthogonal = 'export',
              columns = c(0:6)
            ),
            customize = JS("function(csv) {
              return window.customCsvExport(csv);
            }")
          ),
          list(
            extend = 'excel',
            text = '<i class="fa fa-file-excel" style="margin-right: 5px;"></i> XLSX',
            titleAttr = "Export patient records in XLSX (Excel) format",
            filename = 'patient_records',
            title = NULL,
            exportOptions = list(
              orthogonal = 'export',
              columns = c(0:6)
            ),
            customize = JS("function(xlsx) {
              return window.customExcelExport(xlsx);   
            }")
          ),
          list(
            extend = 'pdf',
            text = '<i class="fa fa-file-pdf" style="margin-right: 5px;"></i> PDF',
            titleAttr = "Export patient records in PDF format",
            filename = 'patient_records',
            title = NULL,
            orientation = "portrait",
            pageSize = "A4",
            exportOptions = list(
              columns = c(0:6)
            ),
            customize = JS("function(doc) {
              return window.customPdfExport(doc);
            }")
          )
        ),
        search = list(
          caseInsensitive = FALSE,
          regex = TRUE,
          smart = FALSE
        ),
        columnDefs = list(
          list(className = 'dt-center', targets = '_all'),
          list(type = 'natural', targets = 0:5),
          list(orderable = FALSE, targets = 7)
        ),
        order = list(list(1, 'desc')),
        pageLength = 20
      )
    ) |>
      formatCurrency(columns = "weight", currency = "", digits = 1) |>
      formatCurrency(columns = "height", currency = "", digits = 2) |>
      formatCurrency(columns = "bmi", currency = "", digits = 2) |>
      formatStyle(
        columns = "weight",
        background = styleColorBar(c(0, max_weight), '#C0C0C0'),
        backgroundSize = '98% 88%',
        backgroundRepeat = 'no-repeat',
        backgroundPosition = 'center'
      ) |>
      formatStyle(
        columns = "height",
        background = styleColorBar(c(0, max_height), '#C0C0C0'),
        backgroundSize = '98% 88%',
        backgroundRepeat = 'no-repeat',
        backgroundPosition = 'center'
      ) |>
      formatStyle(
        columns = "bmi",
        background = styleColorBar(c(0, max_bmi), '#C0C0C0'),
        backgroundSize = '98% 88%',
        backgroundRepeat = 'no-repeat',
        backgroundPosition = 'center'
      ) |>
      formatStyle(
        columns = "bmi_zone",
        backgroundColor = styleEqual(names(zone_colors), unname(zone_colors))
      )
  }, server = FALSE)
  
  #=============================================================================
  # 📝️️️ Handle manual edits and sync with Firebase
  #=============================================================================
  
  observeEvent(input$recordsTable_cell_edit, {
    info <- input$recordsTable_cell_edit
    df <- isolate(patientData())
    col_map <- c("patientId", NA, "sex", "weight", "height", NA, NA)
    col_name <- col_map[info$col + 1]
    if (is.na(col_name)) return()
    df[info$row, col_name] <- info$value
    if (col_name %in% c("weight", "height")) {
      weight <- as.numeric(df[info$row, "weight"])
      height <- as.numeric(df[info$row, "height"])
      df[info$row, "bmi"] <- ifelse(is.na(height) || height == 0, NA, round(weight / (height^2), 2))
      df[info$row, "bmi_zone"] <- bmi_zone(df[info$row, "bmi"])
    }
    
    df <- df[order(df$timestamp, decreasing = TRUE), ]
    rownames(df) <- NULL
    patientData(df)
    
    record_to_update <- df[info$row, ]
    
    current_plot_record <- isolate(lastRecordToPlot())
    if (!is.null(current_plot_record) && current_plot_record$firestore_id == record_to_update$firestore_id) {
      lastRecordToPlot(list(
        firestore_id = record_to_update$firestore_id,
        patientId = record_to_update$patientId,
        weight = record_to_update$weight,
        height = record_to_update$height
      ))
    }
    
    session$sendCustomMessage(type = "updateData", message = list(
      firestore_id = record_to_update$firestore_id,
      patientId = record_to_update$patientId,
      sex = record_to_update$sex,
      weight = as.numeric(record_to_update$weight),
      height = as.numeric(record_to_update$height)
    ))
    showNotification("Record updated successfully!", type = "message", duration = 5)
  })
  
  #=============================================================================
  # 🗑️ Handle row deletion and sync with Firebase
  #=============================================================================
  
  observeEvent(input$delete_firestore_id, {
    req(input$delete_firestore_id)
    id_to_delete <- input$delete_firestore_id
    current_data <- isolate(patientData())
    current_plot_record <- isolate(lastRecordToPlot())
    
    if (!is.null(current_plot_record) && current_plot_record$firestore_id == id_to_delete) {
      lastRecordToPlot(NULL)
    }
    
    updated_data <- current_data[current_data$firestore_id != id_to_delete, ]
    patientData(updated_data)
    
    session$sendCustomMessage(type = "deleteDataOnly", message = list(firestore_id = id_to_delete))
    showNotification("Record deleted successfully.", type = "message", duration = 5)
  })
  
  #=============================================================================
  # 📄 Generate and download patient PDF reportse
  #=============================================================================
  
  output$download_report <- downloadHandler(
    filename = function() {
      record <- lastRecordTable()
      if (is.null(record) || is.null(record$date)) {
        paste0("bmireport_unknownid_date", Sys.Date(), ".pdf")
      } else {
        idnumber <- record$patientId
        dateyyyymmdd <- format(as.POSIXct(record$date), "%Y-%m-%d")
        timehhmmss <- format(as.POSIXct(record$date), "%H.%M.%S")
        paste0("bmireport_id", idnumber, "_date", dateyyyymmdd, "_time", timehhmmss, ".pdf")
      }
    },
    content = function(file) {
      record <- lastRecordTable()
      if (is.null(record)) {
        showNotification("No patient record available to generate report.", type = "error")
        return(NULL)
      }
      
      tempReport <- file.path(tempdir(), "patient-report.Rmd")
      file.copy("patient-report.Rmd", tempReport, overwrite = TRUE)
      
      params <- list(
        date = record$date,
        patient_id = record$patientId,
        sex = record$sex,
        weight = record$weight,
        height = record$height,
        bmi = record$bmi
      )
      
      rmarkdown::render(
        input = tempReport,
        output_file = file,
        params = params,
        envir = new.env(parent = globalenv())
      )
    }
  )
}

#===============================================================================
# 🧩 Run the Shiny app
#===============================================================================

shinyApp(ui, server)
