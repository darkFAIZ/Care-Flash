# Care-Merchant App Flow

Caregiver app flow. Shared matching, payment, booking, verification, and session rules are defined in [Care-Flash-Platform_SRS_IEEE830.md](./Care-Flash-Platform_SRS_IEEE830.md).

```mermaid
flowchart TD
    Start([Open Care-Merchant])
    Account["Create account or log in"]
    SubmitID["Submit student ID and<br/>required verification details"]
    Verified{"Caregiver verified?"}
    Resubmit["View rejection reason<br/>and resubmit if allowed"]
    SafetyTraining["Complete safety module<br/>and receive badge"]
    Availability["Set profile, gender,<br/>and availability"]
    Wait["Wait for eligible request"]
    Offer["Receive request reference, help type,<br/>optional description, boundary checklist,<br/>and expected caregiver pay"]
    Hidden["Client location and private<br/>verification code are hidden"]
    Decision{"Accept request<br/>within response window?"}
    Decline["Decline without rating penalty"]
    WaitAgain["Wait for another request"]
    Accepted["Accept request"]
    Grab["View pickup and destination;<br/>wait for Grab pickup and travel"]
    Danger{"Caregiver reports danger<br/>before session?"}
    PreReport["Cancel booking;<br/>notify support"]
    Arrive["Meet care seeker"]
    VerifyCode{"Check care seeker's<br/>client verification code"}
    Invalid["Platform reports failed verification;<br/>booking cancelled"]
    Generate["Generate/activate booking-linked<br/>QR or NFC for safety button"]
    Handover["Hand physical safety button<br/>to care seeker"]
    Session["Session starts after platform<br/>confirms both verifications"]
    Timer["View boundary checklist<br/>and session timer"]
    Outcome{"Choose session outcome"}
    Complete["Mark work complete"]
    Earnings["View caregiver earnings<br/>and session history"]
    SOS["Tap SOS/Report if in danger"]
    Emergency["Session ends;<br/>report sent to support/emergency response;<br/>compensation policy applied"]
    EarlyEnd["Care seeker ends early"]
    Compensation["View configured 50%<br/>early-end compensation"]
    PostVisit{"Post-session action"}
    Rate["Rate care seeker"]
    Report["Submit report about care seeker<br/>with evidence during/after visit"]
    Feedback["View feedback received<br/>in Care-Merchant"]
    End([Return to availability])

    Start --> Account --> SubmitID --> Verified
    Verified -- No --> Resubmit --> SubmitID
    Verified -- Yes --> SafetyTraining --> Availability --> Wait --> Offer --> Hidden --> Decision
    Decision -- Decline or timeout --> Decline --> WaitAgain --> Wait
    Decision -- Accept --> Accepted --> Grab --> Danger
    Danger -- Yes --> PreReport --> Earnings --> Wait
    Danger -- No --> Arrive --> VerifyCode
    VerifyCode -- Invalid --> Invalid --> Earnings --> Wait
    VerifyCode -- Valid --> Generate --> Handover --> Session --> Timer --> Outcome
    Outcome -- Normal completion --> Complete --> Earnings --> PostVisit
    Outcome -- Care seeker ends early --> EarlyEnd --> Compensation --> Earnings --> PostVisit
    Outcome -- Caregiver SOS/report --> SOS --> Emergency --> Earnings --> PostVisit
    PostVisit -- Rate seeker --> Rate --> Feedback --> End
    PostVisit -- Report seeker --> Report --> Feedback --> End
    PostVisit -- No feedback/report --> Feedback --> End
    End --> Availability
```
