#!/usr/bin/env -S deno run -A

import { Command } from "https://deno.land/x/cliffy@v1.0.0-rc.3/command/mod.ts";
import $ from "https://deno.land/x/dax@0.39.2/mod.ts";

await new Command()
  .name("./create-install-media")
  .description("Create install media for the CoreOS customization")
  .option("-s, --stream <version>", "The CoreOS stream to use", {
    default: "stable",
  })
  .option(
    "-d, --dest-device <device>",
    "The deviceo on which to install CoreOS when the install media is run",
    { required: true }
  )
  .option("-c, --config-url <url>", "The URL to fetch the Ignition file from", {
    default: "https://cprecioso.github.io/homelab/config.ign",
  })
  .option("-p, --platform <platform>", "The platform to create the media for", {
    default: "amd64",
  })
  .option(
    "-o, --output <file>",
    'The output file to write the Ignition file to. "-" for stdout.',
    { default: "-" }
  )
  .action(async ({ configUrl, stream, platform, destDevice, output }) => {
    const installerMediaConfig = JSON.stringify({
      stream,
      "ignition-url": configUrl,
      platform,
      "dest-device": destDevice,
    });
    const installerMediaButaneConfig = JSON.stringify({
      variant: "fcos",
      version: "1.5.0",
      storage: {
        files: [
          {
            path: "/etc/coreos/installer.d/custom.yaml",
            contents: { inline: installerMediaConfig },
          },
        ],
      },
    });

    const config =
      await $`docker run --rm -i quay.io/coreos/butane:release --strict < ${installerMediaButaneConfig}`.text();

    if (output === "-") {
      await Deno.stdout.write(new TextEncoder().encode(config));
    } else {
      await Deno.writeTextFile(output, config);
    }
  })
  .parse(Deno.args);
