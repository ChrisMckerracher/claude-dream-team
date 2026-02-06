---
name: Quality Assurance
description: "Use when planning tests, writing Playwright test suites, executing API tests, validating feature flows, or decomposing product specs into test coverage. Provides test planning frameworks, Playwright patterns, and failure reporting templates."
version: 1.0.0
---

# Quality Assurance Skill

## Test Planning Framework

### From Feature File to Test Plan

1. Read the .feature file from `docs/features/`
2. For each Scenario, create a test case:
   ```
   Test Case: [Scenario name]
   Type: e2e | api | unit
   Priority: critical | high | medium | low
   Steps:
     1. [Given → setup step]
     2. [When → action step]
     3. [Then → assertion step]
   Expected: [What should happen]
   ```
3. Add edge cases not covered by the .feature file
4. Identify which tests need browser vs. API-only

### Test Priority Matrix

| User Impact | Likelihood | Priority |
|------------|------------|----------|
| High | High | Critical - must pass |
| High | Low | High - test thoroughly |
| Low | High | Medium - automated |
| Low | Low | Low - best effort |

## Playwright Test Patterns

### Setup with Video Recording
```typescript
import { test, expect } from '@playwright/test';

test.describe('Feature: [Name]', () => {
  test.use({
    video: 'on',  // Always record video
    screenshot: 'only-on-failure',
    trace: 'retain-on-failure',
  });

  test('[Scenario name]', async ({ page }) => {
    // Given
    await page.goto('/path');

    // When
    await page.click('[data-testid="button"]');

    // Then
    await expect(page.locator('[data-testid="result"]')).toBeVisible();
  });
});
```

### Common Playwright Assertions
```typescript
// Visibility
await expect(element).toBeVisible();
await expect(element).toBeHidden();

// Text content
await expect(element).toHaveText('expected');
await expect(element).toContainText('partial');

// Form state
await expect(input).toHaveValue('value');
await expect(checkbox).toBeChecked();
await expect(button).toBeEnabled();

// Navigation
await expect(page).toHaveURL(/pattern/);
await expect(page).toHaveTitle('Title');

// Network
const response = await page.waitForResponse('**/api/endpoint');
expect(response.status()).toBe(200);
```

### Page Object Pattern
```typescript
class LoginPage {
  constructor(private page: Page) {}

  async login(email: string, password: string) {
    await this.page.fill('[data-testid="email"]', email);
    await this.page.fill('[data-testid="password"]', password);
    await this.page.click('[data-testid="submit"]');
  }

  async expectError(message: string) {
    await expect(this.page.locator('[data-testid="error"]'))
      .toHaveText(message);
  }
}
```

## API Test Patterns

```typescript
// REST API test template
test('POST /api/resource', async ({ request }) => {
  const response = await request.post('/api/resource', {
    data: { name: 'test', value: 42 }
  });

  expect(response.status()).toBe(201);
  const body = await response.json();
  expect(body).toMatchObject({
    id: expect.any(String),
    name: 'test',
    value: 42
  });
});
```

## Failure Report Template

When a test fails, report to the Coding agent:

```markdown
## QA Failure Report

**Task**: [Task ID] - [Title]
**Test**: [Test name]
**Type**: e2e | api | manual
**Severity**: blocker | major | minor

### Steps to Reproduce
1. [Step 1]
2. [Step 2]
3. [Step 3]

### Expected Behavior
[What should happen according to the .feature file]

### Actual Behavior
[What actually happened]

### Evidence
- Video: [path to recording]
- Screenshot: [path if applicable]
- Logs: [relevant error output]

### Possible Root Cause
[Your best guess, if you have one]

### Feature File Reference
[Which scenario from which .feature file]
```

## Full Validation Checklist

During the Full Validation Phase:

- [ ] All .feature files in `docs/features/` are covered by tests
- [ ] All critical flows have video-recorded Playwright tests
- [ ] All API endpoints have request/response validation tests
- [ ] Error flows are tested (not just happy paths)
- [ ] Edge cases from acceptance criteria are covered
- [ ] Test results are saved to `test-results/`
- [ ] Video recordings are in `test-results/videos/`
- [ ] Failure report sent for any broken flows
