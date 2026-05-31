# ytunblock — OpenWrt package based on Waujito/youtubeUnblock
# https://github.com/Waujito/youtubeUnblock

include $(TOPDIR)/rules.mk

PKG_NAME:=ytunblock
PKG_VERSION:=1.3.1
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/Waujito/youtubeUnblock.git
PKG_SOURCE_VERSION:=v1.3.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/ytunblock
	SECTION:=net
	CATEGORY:=Network
	TITLE:=YT Unblock (youtubeUnblock fork)
	DEPENDS:=+libpthread +kmod-nft-queue +kmod-nf-conntrack +firewall4
	URL:=https://github.com/Waujito/youtubeUnblock
	MAINTAINER:=ytunblock-owrt
endef

define Package/ytunblock/description
	Обход DPI для YouTube на основе youtubeUnblock.
	Userspace NFQUEUE обработчик TLS/QUIC трафика.
	Оптимизирован для OpenWrt 23.x–25.x (nftables / firewall4).
endef

define Build/Prepare
	$(call Build/Prepare/Default)
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) \
		PATH="$(TARGET_PATH)" \
		CC="$(TARGET_CC)" \
		CFLAGS="$(TARGET_CFLAGS)" \
		LDFLAGS="$(TARGET_LDFLAGS)" \
		CROSS_COMPILE_PLATFORM="$(TARGET_CROSS:-=)"
endef

define Package/ytunblock/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/build/youtubeUnblock $(1)/usr/bin/youtubeUnblock
	$(LN) youtubeUnblock $(1)/usr/bin/ytunblock
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/ytunblock $(1)/etc/init.d/ytunblock
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/etc/uci-defaults/99-ytunblock $(1)/etc/uci-defaults/99-ytunblock
	$(INSTALL_DIR) $(1)/usr/share/nftables.d/ruleset-post
	$(INSTALL_DATA) ./files/nftables.d/537-ytunblock.nft $(1)/usr/share/nftables.d/ruleset-post/537-ytunblock.nft
	$(INSTALL_DIR) $(1)/usr/share/ytunblock
	$(INSTALL_BIN) ./files/usr/share/ytunblock/defaults.sh $(1)/usr/share/ytunblock/defaults.sh
	$(INSTALL_DIR) $(1)/usr/share/ytunblock/presets
	$(INSTALL_BIN) ./files/usr/share/ytunblock/presets/*.sh $(1)/usr/share/ytunblock/presets/
	$(INSTALL_DIR) $(1)/usr/libexec/ytunblock
	$(INSTALL_BIN) ./files/usr/libexec/ytunblock/* $(1)/usr/libexec/ytunblock/
endef

define Package/ytunblock/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] && exit 0
if [ -x /etc/init.d/firewall ]; then
	/etc/init.d/firewall reload 2>/dev/null || true
fi
exit 0
endef

define Package/ytunblock/prerm
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] && exit 0
/etc/init.d/ytunblock stop 2>/dev/null || true
exit 0
endef

$(eval $(call BuildPackage,ytunblock))
