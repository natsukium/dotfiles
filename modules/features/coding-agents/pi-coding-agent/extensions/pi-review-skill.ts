import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const skillPath = "@piReviewSkill@";

export default function (pi: ExtensionAPI) {
  pi.on("resources_discover", () => {
    if (process.env.PI_REVIEW_WORKER) {
      return;
    }
    return { skillPaths: [skillPath] };
  });
}
