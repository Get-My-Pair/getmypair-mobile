/// Figma: [GetMyPair](https://www.figma.com/design/DQ61w1v0ZSIyDdjTTLRQvv/GetMyPair?node-id=335-1687&m=dev)
/// — Home / dashboard hero & actions. Export icons via **Dev Mode → Copy as MCP asset**
/// and replace URLs below if the design updates.
abstract final class FigmaHomeAssets {
  FigmaHomeAssets._();

  static const String mapPin =
      'https://www.figma.com/api/mcp/asset/6f6d9a2d-7883-48df-aecc-0a14054bc194';
  static const String chevronRight =
      'https://www.figma.com/api/mcp/asset/544a7fbe-dbd4-46d5-a933-fd15130bad98';
  static const String bell =
      'https://www.figma.com/api/mcp/asset/f72f8e91-49da-47ac-b4db-b26a3fe975ab';
  static const String search =
      'https://www.figma.com/api/mcp/asset/86be91f0-2c6b-4d8a-a9c0-97db4c0a436f';
  static const String openRack =
      'https://www.figma.com/api/mcp/asset/5b968dce-9204-4248-83b5-17c081b367be';
  static const String shoeCare =
      'https://www.figma.com/api/mcp/asset/9f457cfb-52e7-4443-8375-28b4d34ada99';
  static const String rent =
      'https://www.figma.com/api/mcp/asset/2d760945-cc07-4a4b-ab56-09d1be0f78e6';
  static const String rehome =
      'https://www.figma.com/api/mcp/asset/94221a3d-53f3-4bf6-88cc-2831fcc37546';

  /// Bottom navigation (node `335:1687` tab bar). When `null`, [FloatingGradientBottomNav]
  /// falls back to Material icons.
  static const String? tabHomeIcon = null;
  static const String? tabServicesIcon = null;
  static const String? tabProfileIcon = null;
}
