# Changelog

All notable changes to OptimisticPanel will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2024-01-XX

### Added
- Initial release of OptimisticPanel library
- `OptimisticPanel.OptimisticModalComponent` - Full-screen modal dialog component
- `OptimisticPanel.OptimisticSlideoverComponent` - Multi-directional sliding panel component
- Sophisticated JavaScript state machine for handling optimistic UI interactions
- Built-in focus management using Phoenix LiveView's `focus_wrap` component
- Comprehensive accessibility features with ARIA support
- Ghost animation system for smooth content transitions
- Support for both optimistic and non-optimistic interaction modes
- Configurable animations, durations, and behaviors
- Full documentation with usage examples and troubleshooting guide

### Features
- **Optimistic UI**: Panels respond immediately to user actions while waiting for server confirmation
- **Focus Management**: Automatic focus trapping and restoration using LiveView's native components
- **Accessibility**: Complete ARIA support, keyboard navigation, and screen reader compatibility
- **Multi-directional Sliding**: Slideover panels can slide from any edge (left, right, top, bottom)
- **State Management**: Robust handling of complex interaction scenarios and race conditions
- **Customizable**: Configurable overlay opacity, animation duration, close behaviors
- **Loading States**: Separate loading and main content slots for better UX
- **Ghost Animations**: Seamless transitions when panel content changes

### Dependencies
- Phoenix LiveView 0.20.0+
- Phoenix 1.7.0+
- Phoenix HTML 4.0+

### Breaking Changes
- None (initial release)