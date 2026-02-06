---
name: Laws of UX Reference
description: "Use when making UI/UX design decisions, reviewing interfaces, or justifying design choices. Provides all 30 Laws of UX with practical application guidance, organized by category for quick reference during design work."
version: 1.0.0
---

# Laws of UX - Complete Reference

A comprehensive reference of UX principles for making informed design decisions. When designing or reviewing UI, reference the relevant laws to justify choices.

## Gestalt Principles (Visual Perception)

### Law of Proximity
**Objects near each other are perceived as a group.**
- Application: Group related form fields, buttons, and information
- Anti-pattern: Unrelated items placed too close together
- Test: Cover labels - can users still guess groupings?

### Law of Similarity
**Similar elements are perceived as a group.**
- Application: Use consistent styling for same-function elements
- Anti-pattern: Buttons that look different but do similar things
- Test: Can users identify all clickable elements at a glance?

### Law of Common Region
**Elements sharing a bounded area are perceived as grouped.**
- Application: Use cards, borders, or backgrounds to group content
- Anti-pattern: Visual boundaries that split related content
- Test: Remove all text - do the visual groups still make sense?

### Law of Uniform Connectedness
**Visually connected elements are perceived as related.**
- Application: Use lines, arrows, or shared colors to show relationships
- Anti-pattern: Connected-looking elements that aren't related
- Test: Can users trace the relationship between connected items?

### Law of Pragnanz (Simplicity)
**Ambiguous images are perceived in the simplest form.**
- Application: Favor clean, simple layouts over complex arrangements
- Anti-pattern: Overly decorative designs that obscure content structure
- Test: Can a new user understand the page in 5 seconds?

## Cognitive & Memory Principles

### Miller's Law
**Working memory holds ~7 items (plus or minus 2).**
- Application: Limit nav items, options in dropdowns, steps in wizards
- Anti-pattern: Menus with 15+ items, forms with 20+ fields on one page
- Guideline: Max 7 items in any single group. Use progressive disclosure for more.

### Chunking
**Break information into meaningful groups.**
- Application: Phone numbers (555-123-4567), credit cards (4 groups of 4)
- Anti-pattern: Long unbroken strings of numbers or text
- Guideline: Group by meaning, not arbitrary length. 3-5 items per chunk.

### Working Memory
**Temporary storage for active cognitive tasks is limited.**
- Application: Don't require users to remember info from a previous page
- Anti-pattern: Multi-step forms that reference earlier inputs without showing them
- Guideline: Show relevant context in-place. Reduce memory load.

### Serial Position Effect
**First and last items in a list are remembered best.**
- Application: Put important items first and last in navigation/lists
- Anti-pattern: Burying the most important option in the middle
- Guideline: Critical actions at start or end. Least important in the middle.

### Zeigarnik Effect
**Unfinished tasks are remembered better than completed ones.**
- Application: Progress bars, checklists, "3 of 5 steps completed"
- Anti-pattern: No indication of progress in multi-step processes
- Guideline: Show progress. Use this to drive completion of onboarding flows.

### Mental Model
**Users have preconceived notions of how things should work.**
- Application: Follow platform conventions. Trash icon = delete.
- Anti-pattern: Novel interaction patterns for common actions
- Guideline: Match user expectations. Innovate on value, not on basic interactions.

## Decision-Making & Behavior

### Hick's Law
**Decision time increases with the number and complexity of choices.**
- Application: Reduce options. Use smart defaults. Progressive disclosure.
- Formula: RT = a + b * log2(n) where n = number of choices
- Anti-pattern: Overwhelming settings pages, too many CTAs on one screen
- Guideline: 3-5 options ideal. More than 7 requires categorization.

### Choice Overload
**Too many options leads to decision paralysis.**
- Application: Curate options. Provide recommendations. Allow filtering.
- Anti-pattern: Product pages with 50 variants and no guidance
- Guideline: Highlight a recommended option. Allow comparison of 2-3 at most.

### Goal-Gradient Effect
**Motivation increases as people approach a goal.**
- Application: Show progress. Start progress bars partially filled.
- Anti-pattern: Long processes with no visible progress
- Guideline: Break long processes into visible milestones.

### Parkinson's Law
**Tasks expand to fill available time.**
- Application: Set reasonable deadlines, time limits for sessions
- Anti-pattern: Open-ended forms with no indication of expected effort
- Guideline: Provide time estimates. "This takes about 2 minutes."

### Paradox of the Active User
**Users don't read instructions - they jump straight in.**
- Application: Design for immediate use. Inline guidance, not manuals.
- Anti-pattern: Requiring users to read documentation before using features
- Guideline: Progressive disclosure. Tooltips over tutorials.

## Performance & Interaction

### Fitts's Law
**Target acquisition time = f(distance, size).**
- Formula: MT = a + b * log2(1 + D/W) where D=distance, W=width
- Application: Make important buttons large and close to the cursor
- Anti-pattern: Tiny click targets, important actions far from context
- Guidelines:
  - Minimum touch target: 44x44px (mobile), 24x24px (desktop)
  - Place primary actions near likely cursor position
  - Edge/corner placement = effectively infinite size (screen edges)

### Doherty Threshold
**Keep system response under 400ms for flow state.**
- Application: Optimistic UI, loading skeletons, instant feedback
- Anti-pattern: Spinners for every action, no feedback during processing
- Guidelines:
  - < 100ms: feels instant
  - 100-400ms: noticeable but acceptable
  - > 400ms: add loading indicator
  - > 1000ms: add progress indicator

### Flow
**Users achieve peak productivity in a state of deep focus.**
- Application: Minimize interruptions, reduce friction, clear next steps
- Anti-pattern: Pop-ups, unnecessary confirmations, context switches
- Guideline: Every interruption costs 15-20 minutes of re-focus time.

## Perception & Judgment

### Aesthetic-Usability Effect
**Beautiful designs are perceived as more usable.**
- Application: Invest in visual polish. First impressions matter.
- Anti-pattern: Functional but ugly interfaces erode trust
- Guideline: Visual quality is not optional - it affects perceived usability.

### Von Restorff Effect (Isolation Effect)
**The different item in a group is most memorable.**
- Application: Make CTAs visually distinct. Highlight important info.
- Anti-pattern: Everything is bold/colored (nothing stands out)
- Guideline: Use visual distinction sparingly for maximum impact.

### Cognitive Bias
**Systematic errors in thinking affect user decisions.**
- Application: Be aware of anchoring, confirmation bias, status quo bias
- Ethical note: Use awareness of bias to help users, never to manipulate
- Guideline: Provide balanced information for decision-making.

### Peak-End Rule
**Experiences judged by peak moment and ending.**
- Application: End flows positively. Celebrate completions.
- Anti-pattern: Error messages as the last thing users see
- Guideline: Success states and thank-you pages deserve design attention.

### Selective Attention
**Users focus on relevant stimuli and ignore the rest.**
- Application: Make important elements visually salient
- Anti-pattern: Banner blindness, important info in ad-like locations
- Guideline: Don't put critical information in areas users have learned to ignore.

## Design Principles

### Jakob's Law
**Users expect your site to work like other sites they know.**
- Application: Follow platform conventions. Use standard patterns.
- Anti-pattern: Custom scrollbars, non-standard navigation, novel icons
- Guideline: Innovate on content and value, not on basic interaction patterns.

### Occam's Razor
**The simplest solution is usually the best.**
- Application: Remove unnecessary elements. Simplify flows.
- Anti-pattern: Feature creep, options for every edge case
- Guideline: When in doubt, remove. You can always add later.

### Postel's Law (Robustness Principle)
**Be liberal in what you accept, conservative in what you send.**
- Application: Accept varied input formats. Display clean, consistent output.
- Anti-pattern: Rigid input validation (rejecting "555.123.4567" as phone number)
- Guideline: Parse what you can. Format for display. Only reject truly invalid input.

### Tesler's Law (Conservation of Complexity)
**Every system has irreducible complexity. Someone must deal with it.**
- Application: Absorb complexity in the system, not the user interface
- Anti-pattern: Exposing system complexity to users (raw error codes, config files)
- Guideline: Move complexity to the backend. Simplify what users see.

### Pareto Principle (80/20 Rule)
**80% of effects come from 20% of causes.**
- Application: Optimize the 20% of features used 80% of the time
- Anti-pattern: Equal design effort on rarely-used features
- Guideline: Identify core workflows and make them excellent.
