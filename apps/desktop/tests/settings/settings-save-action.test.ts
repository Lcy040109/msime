import { expect, test, vi } from "vitest";
import { createSettingsSaveAction } from "@lingyao/ui";

test("prevents form navigation and saves settings", () => {
  const preventDefault = vi.fn();
  const save = vi.fn().mockResolvedValue(undefined);
  const submit = createSettingsSaveAction({ save });

  submit({ preventDefault } as never);

  expect(preventDefault).toHaveBeenCalledOnce();
  expect(save).toHaveBeenCalledOnce();
});
