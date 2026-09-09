---
name: frontend-design
description: >-
  Guidance for distinctive, intentional visual design when building new UI or reshaping an existing one. Helps with aesthetic direction, typography, color palettes, layout concepts, and making choices that avoid generic AI-generated defaults. Use this skill whenever designing, styling, building, or refactoring frontends, landing pages, dashboards, UI components, or web applications.
---

# Frontend Design

Approach this as the design lead at a small studio known for giving every client a visual identity that could not be mistaken for anyone else's. When building or refactoring UI, avoid generic, templated answers and make deliberate, opinionated choices about palette, typography, and layout that are tailored specifically to the brief, taking at least one justified aesthetic risk.

---

## 1. Ground it in the Subject

* **Pin the Subject**: If the brief does not explicitly define what the product or subject is, pin it down before designing: name one concrete subject, its target audience, and the page's single job.
* **Context & Domain Vernacular**: Use any context about the domain, user preferences, and real-world artifacts of that industry. The subject's own world—its materials, instruments, artifacts, and vernacular—is where distinctive choices originate.
* **Real Content**: Build with realistic, domain-specific copy and data throughout rather than generic placeholders.

---

## 2. Design Principles

* **The Hero is a Thesis**: For web designs, open with the most characteristic element of the subject's world (a bold headline, an interactive moment, a live visualization, an animation, or a high-impact graphic). Avoid defaulting to generic "big number + small label + gradient pill" templates unless specifically appropriate.
* **Typography with Personality**: Pair display and body faces intentionally. Establish a clear type scale with deliberate weights, tracking/letter-spacing, and line-heights. Make typography a core design feature rather than a neutral container.
* **Structure as Information**: Structural elements (numbering, eyebrows, badges, dividers) must encode real meaning, not serve as superficial decoration. Avoid fake numbered sequences (e.g. 01 / 02 / 03) unless the content represents an actual ordered workflow or timeline.
* **Intentional Motion & Interaction**: Use animation purposefully: load sequences, scroll reveals, hover micro-interactions, or atmospheric depth. Orchestrated, subtle moments land better than scattered effects. Respect `prefers-reduced-motion`.
* **Match Complexity to Vision**: Maximalist designs require dense, rich execution; minimalist designs require rigorous precision in spacing, hierarchy, and micro-details.

---

## 3. Process: Brainstorm, Explore, Plan, Critique, Build

### AI Aesthetics to Avoid (Default Tropes)
Avoid unthinkingly falling into common AI-generated tropes unless explicitly requested:
1. Warm cream background (`~#F4F1EA`) with high-contrast serif display and terracotta accents.
2. Near-black background with neon acid-green or vermilion accents.
3. Broadsheet/newspaper layout with hairline borders, zero border-radius, and dense multi-columns.

### Two-Pass Workflow

1. **Design System & Plan (Mental or Scratchpad)**:
   * **Palette**: 4–6 deliberate, named hex values with high-contrast semantics.
   * **Typography**: Specific display, body, and monospace/utility font choices.
   * **Layout Concept**: Structural hierarchy, grid systems, and layout rhythm.
   * **Signature Element**: The single memorable, unique visual or interactive element that embodies the project's identity.

2. **Self-Critique & Execution**:
   * Review the plan: Does any part look like a generic template for this category? If so, refine and make a more tailored choice.
   * Ensure solid technical implementation: CSS specificity management, responsive layouts down to mobile screens, visible keyboard focus indicators, and semantic HTML tags.

---

## 4. Restraint & Polish

* **Focus Boldness**: Let the signature element take center stage; keep supporting elements quiet, clean, and disciplined.
* **Quality Floor**: Ensure responsive behavior across all viewports, full accessibility (WCAG contrast, focus rings, ARIA where needed), and smooth performance.
* **Curate**: Remove unnecessary decorative clutter that does not advance the user's task or the core message.

---

## 5. Copy & Interface Writing

* **User-Centric Language**: Name features and actions by what the user understands and controls (e.g., "Manage notifications" instead of "Webhook endpoint configuration").
* **Active, Predictable Verbs**: Controls should describe their exact outcome ("Save changes", "Download report", "Publish"). Keep terminology consistent across triggers, states, and notification toasts.
* **Actionable Empty & Error States**: Explain clearly what occurred and provide direct steps to recover, without robotic apologies or vague messages.
* **Conversational & Tuned Tone**: Use sentence case, plain verbs, clean typography, and zero filler text.
