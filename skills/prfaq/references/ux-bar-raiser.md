# UX Bar Raiser Lens

The UX bar raiser evaluates whether a real customer can go from awareness to value without help, training, or frustration. Not whether the product is usable in a lab — whether it survives contact with a distracted person who has a dozen other things competing for their attention. This guide owns the Usability risk dimension and directly sharpens the Customer Quote and Getting Started sections.

## The Gut Check

**Would I switch from my current workflow to use this?**

Customers do not adopt products because they are better in the abstract. They adopt products when the switching cost — learning a new tool, migrating data, changing habits — is lower than the pain of their current approach. A product that is 20% better but requires a complete workflow change will lose to the status quo every time.

The PR/FAQ must make the case that the value is worth the switch. If the Getting Started section reveals significant switching cost, the usability risk is higher than claimed.

## The Full Customer Journey

Usability is not just the interface. It is the entire journey from first hearing about the product to becoming a habitual user. The PR/FAQ should be evaluated at every stage.

### 1. Awareness

How does the customer first encounter this product? The press release subheading is the test: does it communicate the value in one sentence, in the customer's language?

**Check:** Can a customer who reads only the heading and subheading decide whether to keep reading? If the subheading requires domain knowledge or jargon, awareness fails.

### 2. Evaluation

The customer is deciding whether to invest time. The external FAQs ("What is it?", "How is this different?", "How much does it cost?") are the evaluation experience.

**Check:** Do the external FAQs answer the customer's questions in the order they would ask them? The first question is always "is this for me?" not "how does it work technically?"

### 3. Onboarding

The Getting Started section is the onboarding experience. Three steps, value in minutes.

**Check the three-step rule:**
- Step 1 should require no account creation, installation, or configuration if possible
- Step 2 should involve the customer's own data or context (not a demo)
- Step 3 should deliver observable value (not "explore the dashboard")

If any step requires reading documentation, watching a video, or contacting support, the onboarding has failed.

### 4. First Value

The moment the customer says "this is useful." This must happen before any commitment (payment, data migration, team rollout).

**Check:** The Customer Quote should describe this moment. If the quote describes a benefit that only appears after weeks of use, the time-to-first-value is too long.

### 5. Habit Formation

The customer returns without prompting. This is where most products fail — they deliver initial value but don't become part of the customer's routine.

**Check:** Does the PR/FAQ describe a trigger (event, notification, workflow moment) that brings the customer back? A product without a natural return trigger depends on the customer remembering it exists.

## Cognitive Load of Onboarding

Every new concept the customer must learn is cognitive load. Cognitive load determines whether onboarding succeeds or the customer gives up.

### Sources of Cognitive Load

| Source | Example | Mitigation |
|--------|---------|------------|
| **New vocabulary** | Product-specific terms the customer doesn't know | Use the customer's existing vocabulary. If you need a new term, define it in context, not in a glossary |
| **New mental model** | The product organizes information differently than the customer expects | Map to familiar concepts. "Projects" not "workspaces." "Messages" not "communications" |
| **Configuration choices** | Settings the customer must decide before getting value | Provide sensible defaults. Every required configuration step is a drop-off point |
| **Navigation complexity** | Multiple screens, menus, or modes to learn | Minimize surface area at onboarding. Progressive disclosure — show more as the customer matures |
| **Error interpretation** | Error messages the customer must decode | Errors should state what happened, why, and what to do next. Never show stack traces, error codes, or system internals |

### What to Check in the PR/FAQ

- Does the Getting Started section introduce more than one new concept?
- Does the Solution section use terms the customer wouldn't use?
- Does the Getting Started section require the customer to make choices before they have context to make them?

## Mental Model Alignment

The product should work the way the customer already thinks about the problem. When the product's model conflicts with the customer's model, the customer doesn't learn the product's model — they make errors and leave.

### Signals of Misalignment

- The product uses a different word for a concept the customer already has a word for
- The product groups features by technical architecture rather than by customer task
- Undo and cancel behave differently in different contexts
- The customer must learn the system's internal state to use it effectively ("the job is queued" — what does that mean for me?)

### What to Check in the PR/FAQ

- Does the Solution section describe the experience from the customer's perspective or from the system's perspective?
- Would the customer recognize the problem description as their own words?
- Does the Feature Appendix organize features by customer outcome or by system component?

## Accessibility

Accessibility is not a feature — it is a quality standard. A product that works only for users with perfect vision, hearing, motor control, and cognitive capacity is an incomplete product.

### Minimum Questions for the PR/FAQ

1. **Does the product work with a screen reader?** If the product has a visual interface, this is not optional.
2. **Does the product work without a mouse?** Keyboard navigation is both an accessibility and a power-user requirement.
3. **Does the product work at 200% zoom?** Many users with low vision use browser zoom rather than screen readers.
4. **Are color and sound used as the only signal for any state?** Color-blind users (8% of men) cannot distinguish red/green status indicators. Deaf users cannot hear notification sounds.

A PR/FAQ does not need to solve every accessibility requirement upfront, but the Usability risk rating should reflect whether accessibility has been considered. A product targeting enterprise customers may face legal requirements (ADA, WCAG 2.1 AA).

## Error Recovery

How the product behaves when something goes wrong reveals more about usability than how it behaves when everything goes right.

### Principles

- **Errors should be preventable.** The best error message is one the customer never sees. Disable invalid actions rather than allowing them and showing an error.
- **Errors should be recoverable.** Every destructive action should be undoable, or at minimum should require confirmation.
- **Errors should be understandable.** "Something went wrong" is not an error message. "Your file is too large (50MB limit). Try compressing it or splitting it into smaller files." is.
- **Errors should never lose work.** If the customer has entered data and the system errors, the data must be preserved.

### What to Check in the PR/FAQ

- Does the Getting Started section have any step where the customer could fail? If so, what happens?
- Does the external FAQ address "what if something goes wrong?"
- Does the product handle the case where the customer provides bad input gracefully?

## Sharpening the Customer Quote

The Customer Quote is the emotional proof point for usability. A strong customer quote describes the before and after in terms of the customer's lived experience, not the product's features.

### The Quote Should Answer

1. **What was life like before?** — a specific, concrete frustration
2. **What is life like after?** — a specific, concrete improvement
3. **What was the moment of realization?** — the first time the customer thought "this is better"

### Weak vs. Strong Quotes

**Weak:** "The product is intuitive and easy to use. It saves me a lot of time."
- No concrete detail. Could describe any product. Does not prove usability.

**Strong:** "I used to spend my first hour every Monday building the weekly report from three different dashboards. Now it's waiting in my inbox when I get my coffee. My team thinks I got more organized — I just got a better tool."
- Specific time. Specific task. Specific before/after. The usability is demonstrated, not claimed.

## Sharpening the Getting Started Section

The Getting Started section is the single most important usability artifact in the PR/FAQ. If you cannot describe onboarding in three steps that end in value, the product is too complex.

### Common Failures

- **Step 1 is "Sign up"** — account creation is friction, not a step. The customer should experience value before committing identity.
- **Step 2 is "Configure your settings"** — configuration is the product's problem, not the customer's. Provide defaults.
- **Step 3 is "Explore the dashboard"** — exploration is not value. The customer should see a result, solve a problem, or produce an output.

### The Test

Rewrite the three steps as: "In [timeframe], you [action], [action], and [outcome]."

**Weak:** "In 30 minutes, you create an account, configure your workspace, and explore the dashboard."

**Strong:** "In 5 minutes, you paste your data, see the analysis, and share the report."

If the rewrite does not end with a customer outcome, the Getting Started section needs revision.
