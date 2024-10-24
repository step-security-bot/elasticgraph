/** @type {import('tailwindcss').Config} */
module.exports = {
  // Includes .yaml because we extract CSS classes to .yaml files like _config.yaml for reuse.
  content: ["./src/**/*.html", "./src/**/*.md", "./src/**/*.svg", "./src/**/*.yaml"],
  theme: {
    extend: {},
  },
  plugins: [require("@tailwindcss/typography")],
};
