// Configure Tailwind to use class-based dark mode
tailwind.config = {
  darkMode: 'class',
  // Safelist common dark mode classes that Tailwind CDN might not detect
  safelist: [
    'dark:bg-gray-800',
    'dark:bg-gray-900',
    'dark:bg-gray-700',
    'dark:text-white',
    'dark:text-gray-100',
    'dark:text-gray-200',
    'dark:text-gray-300',
    'dark:text-gray-400',
    'dark:border-gray-700',
    'dark:border-gray-600',
    'dark:hover:bg-gray-700',
    'dark:hover:bg-gray-600',
    'dark:bg-blue-900',
    'dark:bg-blue-900/30',
    'dark:bg-red-900',
    'dark:bg-yellow-900',
    'dark:bg-green-900',
    'dark:text-blue-300',
    'dark:text-red-200',
    'dark:text-red-300',
    'dark:text-yellow-200',
    'dark:text-green-300',
    'dark:group-hover:border-gray-300',
  ]
}
