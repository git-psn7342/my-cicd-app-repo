test('basic test - math works', () => {
  expect(1 + 1).toBe(2);
});

test('string test', () => {
  expect('hello pipeline').toContain('pipeline');
});
