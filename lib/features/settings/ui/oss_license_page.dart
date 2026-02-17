import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n.dart';
import '../../../oss_licenses.dart';

class OssLicensePage extends ConsumerWidget {
  const OssLicensePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fTheme = FTheme.of(context);
    final locale = ref.watch(localeProvider);

    return ColoredBox(
      color: fTheme.colors.background,
      child: FScaffold(
        header: FHeader(
          title: Row(
            children: [
              FTappable(
                onPress: () => Navigator.of(context).pop(),
                child: PhosphorIcon(
                  PhosphorIcons.arrowLeft(),
                  size: 20,
                  color: fTheme.colors.foreground,
                ),
              ),
              const SizedBox(width: 12),
              PhosphorIcon(
                PhosphorIcons.scroll(),
                size: 20,
                color: fTheme.colors.primary,
              ),
              const SizedBox(width: 10),
              Text(
                L.of(locale, 'oss_licenses'),
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _allLicenses.length,
          separatorBuilder: (context, index) => const FDivider(),
          itemBuilder: (context, index) {
            final package = _allLicenses[index];
            return FTappable(
              onPress: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PackageLicensePage(package: package),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            package.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: fTheme.colors.foreground,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${package.version ?? ""} ${package.description}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: fTheme.colors.mutedForeground,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PhosphorIcon(
                      PhosphorIcons.caretRight(),
                      size: 18,
                      color: fTheme.colors.mutedForeground,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static const _allLicenses = [...allDependencies, _ibmPlexSansJp, _geist];

  static const _ibmPlexSansJp = Package(
    name: 'IBM Plex Sans JP',
    description: 'An open source Japanese typeface family from IBM.',
    authors: ['IBM'],
    version: '1.1.0',
    isMarkdown: false,
    isSdk: false,
    dependencies: [],
    devDependencies: [],
    homepage: 'https://github.com/IBM/plex',
    license: _oflLicense,
  );

  static const _geist = Package(
    name: 'Geist',
    description:
        'A font family created by Vercel in collaboration with Basement Studio.',
    authors: ['Vercel', 'Basement Studio'],
    version: '1.0.0',
    isMarkdown: false,
    isSdk: false,
    dependencies: [],
    devDependencies: [],
    homepage: 'https://vercel.com/font',
    license: _oflLicense,
  );

  static const _oflLicense =
      '''Copyright (c) 2017 IBM Corp. with Reserved Font Name "Plex"
Copyright (c) 2023 Vercel Inc.

This Font Software is licensed under the SIL Open Font License, Version 1.1.
This license is available with a FAQ at: http://scripts.sil.org/OFL

-----------------------------------------------------------
SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007
-----------------------------------------------------------

PREAMBLE
The goals of the Open Font License (OFL) are to stimulate worldwide
development of collaborative font projects, to support the font creation
efforts of academic and linguistic communities, and to provide a free and
open framework in which fonts may be shared and improved in partnership
with others.

The OFL allows the licensed fonts to be used, studied, modified and
redistributed freely as long as they are not sold by themselves. The
fonts, including any derivative works, can be bundled, embedded,
redistributed and/or sold with any software provided that any reserved
names are not used by derivative works. The fonts and derivatives,
however, cannot be released under any other type of license. The
requirement for fonts to remain under this license does not apply
to any document created using the fonts or their derivatives.

DEFINITIONS
"Font Software" refers to the set of files released by the Copyright
Holder(s) under this license and clearly marked as such. This may
include source files, build scripts and documentation.

"Reserved Font Name" refers to any names specified as such after the
copyright statement(s).

"Original Version" refers to the collection of Font Software components as
distributed by the Copyright Holder(s).

"Modified Version" refers to any derivative made by adding to, deleting,
or substituting -- in part or in whole -- any of the components of the
Original Version, by changing formats or by porting the Font Software to a
new environment.

"Author" refers to any designer, engineer, programmer, technical
writer or other person who contributed to the Font Software.

PERMISSION & CONDITIONS
Permission is hereby granted, free of charge, to any person obtaining
a copy of the Font Software, to use, study, copy, merge, embed, modify,
redistribute, and sell modified and unmodified copies of the Font
Software, subject to the following conditions:

1) Neither the Font Software nor any of its individual components,
in Original or Modified Versions, may be sold by itself.

2) Original or Modified Versions of the Font Software may be bundled,
redistributed and/or sold with any software, provided that each copy
contains the above copyright notice and this license. These can be
included either as stand-alone text files, human-readable headers or
in the appropriate machine-readable metadata fields within text or
binary files as long as those fields can be easily viewed by the user.

3) No Modified Version of the Font Software may use the Reserved Font
Name(s) unless explicit written permission is granted by the corresponding
Copyright Holder. This restriction only applies to the primary font name as
presented to the users.

4) The name(s) of the Copyright Holder(s) or the Author(s) of the Font
Software shall not be used to promote, endorse or advertise any
Modified Version, except to acknowledge the contribution(s) of the
Copyright Holder(s) and the Author(s) or with their explicit written
permission.

5) The Font Software, modified or unmodified, in part or in whole,
must be distributed entirely under this license, and must not be
distributed under any other license. The requirement for fonts to
remain under this license does not apply to any document created
using the Font Software.

TERMINATION
This license becomes null and void if any of the above conditions are
not met.

DISCLAIMER
THE FONT SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT
OF COPYRIGHT, PATENT, TRADEMARK, OR OTHER RIGHT. IN NO EVENT SHALL THE
COPYRIGHT HOLDER BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
INCLUDING ANY GENERAL, SPECIAL, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL
DAMAGES, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF THE USE OR INABILITY TO USE THE FONT SOFTWARE OR FROM
OTHER DEALINGS IN THE FONT SOFTWARE.''';
}

class PackageLicensePage extends ConsumerWidget {
  final Package package;

  const PackageLicensePage({super.key, required this.package});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fTheme = FTheme.of(context);
    final locale = ref.watch(localeProvider);

    return ColoredBox(
      color: fTheme.colors.background,
      child: FScaffold(
        header: FHeader(
          title: Row(
            children: [
              FTappable(
                onPress: () => Navigator.of(context).pop(),
                child: PhosphorIcon(
                  PhosphorIcons.arrowLeft(),
                  size: 20,
                  color: fTheme.colors.foreground,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                package.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (package.description.isNotEmpty) ...[
                Text(
                  L.of(locale, 'description'),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    fontSize: 16,
                    color: fTheme.colors.foreground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  package.description,
                  style: TextStyle(color: fTheme.colors.foreground),
                ),
                const SizedBox(height: 20),
              ],
              if (package.version != null) ...[
                Text(
                  L.of(locale, 'version'),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    fontSize: 16,
                    color: fTheme.colors.foreground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  package.version!,
                  style: TextStyle(color: fTheme.colors.foreground),
                ),
                const SizedBox(height: 20),
              ],
              if (package.homepage != null || package.repository != null) ...[
                Text(
                  L.of(locale, 'links'),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    fontSize: 16,
                    color: fTheme.colors.foreground,
                  ),
                ),
                const SizedBox(height: 8),
                if (package.homepage != null)
                  Text(
                    '${L.of(locale, 'homepage')}: ${package.homepage}',
                    style: TextStyle(color: fTheme.colors.foreground),
                  ),
                if (package.repository != null)
                  Text(
                    '${L.of(locale, 'repository')}: ${package.repository}',
                    style: TextStyle(color: fTheme.colors.foreground),
                  ),
                const SizedBox(height: 20),
              ],
              Text(
                L.of(locale, 'license'),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  fontSize: 16,
                  color: fTheme.colors.foreground,
                ),
              ),
              const SizedBox(height: 8),
              FCard(
                child: Text(
                  package.license ?? L.of(locale, 'no_license'),
                  style: GoogleFonts.geistMono(
                    fontSize: 12,
                    color: fTheme.colors.foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
