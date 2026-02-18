import type { CapacitorConfig } from "@capacitor/cli";

const config: CapacitorConfig = {
  appId: "com.schooltrack.app",
  appName: "SchoolTrack",
  webDir: "dist/public",
  bundledWebRuntime: false,
  server: {
    androidScheme: "https",
  },
};

export default config;
