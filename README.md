# Care-Flash

Care-Flash is a two-sided care service platform with two separate Flutter apps that share one backend:

- **Care-Flash** — care seeker application.
- **Care-Merchant** — caregiver application.

## Software requirements

- [Care-Flash care seeker SRS](./docs/Care-Flash_SRS_IEEE830.md)
- [Care-Merchant caregiver SRS](./docs/Care-Merchant_SRS_IEEE830.md)
- [Shared platform SRS](./docs/Care-Flash-Platform_SRS_IEEE830.md)

## Mermaid diagrams

- [Care-Flash care seeker flow](./docs/Care-Flash_Mermaid.md)
- [Care-Merchant caregiver flow](./docs/Care-Merchant_Mermaid.md)
- [Shared platform architecture and lifecycle](./docs/Care-Flash-Platform_Mermaid.md)


## Planned Repository Structure

We will use a **Monorepo architecture** managed with **Melos** to share code (like models, API clients, or UI components) between both apps in the future.

```text
├── apps/
│   ├── care-flash/          # Flutter app for Care Seekers (To be developed)
│   └── care-merchant/       # Flutter app for Caregivers (To be developed)
├── packages/
│   └── care_flash_core/     # Shared Dart/Flutter code (Models, Shared APIs)
├── docs/                    # IEEE 830 SRS & Mermaid Documentation
├── melos.yaml               # Monorepo management configuration
└── README.md                # Main entry point
```

## Setup & Prerequisites (For Developers)

To prepare your local environment for development, ensure you have the following installed:

1. **Flutter SDK**: Recommended version `^3.24.x` or latest stable.
2. **Melos**: Install globally via pub to manage the monorepo:
   ```bash
   dart pub global activate melos
   ```


### Initializing the Project

Once the workspace structures are generated, running the project will be as simple as:

```bash
# 1. Clone the repository
git clone https://github.com
cd Care-Flash

# 2. Bootstrap all apps and packages simultaneously (Runs pub get everywhere)
melos bootstrap
```
