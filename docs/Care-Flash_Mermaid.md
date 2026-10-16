# Care-Flash App Flow

Care seeker app flow. Shared matching, pricing, payment, booking, and session rules are defined in [Care-Flash-Platform_SRS_IEEE830.md](./Care-Flash-Platform_SRS_IEEE830.md).

```mermaid
flowchart TD
    Start([Open Care-Flash])
    NeedHelp["Tap Need Help"]
    Help["Choose help type<br/>Optionally add description"]
    Boundaries["Set allowed/disallowed<br/>boundary checklist"]
    Visit["Set location, date/time,<br/>and visit duration"]
    Estimate["View preliminary estimated price"]
    Gender["Choose caregiver gender:<br/>male, female, or both"]
    Search["Submit request to shared platform"]
    Match{"Matching caregiver found?"}
    NoMatch["View no-match status"]
    Change{"Change filter or cancel?"}
    Profile["View matched caregiver profile<br/>and rating"]
    Breakdown["Review price breakdown:<br/>caregiver: IDR 25,000 / 30 min<br/>platform fee: 5%<br/>Grab: estimated fare"]
    Pay["Choose payment method and pay"]
    PaymentOK{"Payment successful?"}
    Retry{"Retry payment?"}
    Code["Receive private client<br/>verification code"]
    Waiting["View booking and Grab status<br/>Caregiver location/code remain hidden until acceptance"]
    Arrival["Receive caregiver arrival notice"]
    Scan["Ask for safety button;<br/>scan QR or read NFC"]
    Verified{"Platform verifies button<br/>and caregiver verified client code?"}
    Failed["View automatic report and<br/>booking cancellation status"]
    Session["Session starts;<br/>view session status"]
    Choice{"Choose session action"}
    Normal["Caregiver completes session"]
    NormalPay["Platform releases caregiver service payment<br/>and settles applicable fees"]
    Early["Tap End Early"]
    EarlyResult["Session ends;<br/>caregiver receives configured 50% compensation"]
    Report["Tap Report or press<br/>physical safety button"]
    ReportResult["Session ends;<br/>report sent to support/emergency response;<br/>care seeker payment returned"]
    PostSession{"Choose optional post-session actions"}
    Feedback["Rate and give feedback<br/>about caregiver"]
    AppFeedback["Give separate feedback<br/>about Care-Flash app"]
    Evidence["Submit incident report<br/>with evidence during/after visit"]
    End([Done])

    Start --> NeedHelp --> Help --> Boundaries --> Visit --> Estimate --> Gender --> Search --> Match
    Match -- No --> NoMatch --> Change
    Change -- Change filter --> Gender
    Change -- Cancel --> End
    Match -- Yes --> Profile --> Breakdown --> Pay --> PaymentOK
    PaymentOK -- No --> Retry
    Retry -- Yes --> Pay
    Retry -- No --> End
    PaymentOK -- Yes --> Code --> Waiting --> Arrival --> Scan --> Verified
    Verified -- No --> Failed --> End
    Verified -- Yes --> Session --> Choice
    Choice -- Normal completion --> Normal --> NormalPay --> PostSession
    Choice -- Early end --> Early --> EarlyResult --> PostSession
    Choice -- Report --> Report --> ReportResult --> Evidence --> End
    PostSession -- Caregiver feedback --> Feedback --> AppFeedback --> End
    PostSession -- Incident evidence --> Evidence --> End
    PostSession -- Skip --> End
```
