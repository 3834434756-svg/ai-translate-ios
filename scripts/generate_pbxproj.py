#!/usr/bin/env python3
"""Generate Xcode project.pbxproj for AI-Translate"""
import os, uuid

def uid(): return uuid.uuid4().hex[:24].upper()
P = "AI-Translate"
BID = "com.airanslate.app"
DT = "16.0"
SV = "5.0"
SRC = ["App/AI_TranslateApp.swift","Views/ContentView.swift","Views/SettingsView.swift",
       "Services/TranslationService.swift","Services/SpeechManager.swift","Services/FloatingWindowManager.swift"]
RES = ["Assets.xcassets"]
PLIST = "Info.plist"

# UUIDs
PID = uid(); TID = uid(); BCL = uid(); BCLP = uid()
CD = uid(); CR = uid(); CDP = uid(); CRP = uid()
FB = uid(); RB = uid(); SB = uid()
MF = uid(); MP = uid(); SP = uid(); GRP = uid(); GRES = uid()
FREFS = {f: uid() for f in SRC+RES+[PLIST]}
SRC_BFS = [uid() for _ in SRC]; RES_BFS = [uid() for _ in RES]
SCHEME = uid()

out = []
out.append("// !$*UTF8*$!")
out.append("{")
out.append("  archiveVersion = 1;")
out.append("  classes = {};")
out.append("  objectVersion = 56;")
out.append(f"  rootObject = {PID};")
out.append("")

# Objects
out.append("  objects = {")
out.append(f"    {PID} = {{isa=PBXProject;attributes={{BuildIndependentTargetsInParallel=1;}};buildConfigurationList={BCLP};compatibilityVersion=\"Xcode 14.0\";developmentRegion=en;hasScannedForEncodings=0;knownRegions=(en,Base,ja,\"zh-Hans\");mainGroup={MP};productRefGroup={GRES};projectDirPath=\"\";projectRoot=\"\";targets=({TID});}};")

out.append(f"    {TID} = {{isa=PBXNativeTarget;buildConfigurationList={BCL};buildPhases=({SB},{RB},{FB});buildRules=();dependencies=();name={P};productName={P};productReference={MF};productType=\"com.apple.product-type.application\";}};")

out.append(f"    {BCL} = {{isa=XCConfigurationList;buildConfigurations=({CD},{CR});defaultConfigurationIsVisible=0;defaultConfigurationName=Release;}};")
out.append(f"    {BCLP} = {{isa=XCConfigurationList;buildConfigurations=({CDP},{CRP});defaultConfigurationIsVisible=0;defaultConfigurationName=Release;}};")

for uid_s, name, proj in [(CD,"Debug",False),(CR,"Release",False),(CDP,"Debug",True),(CRP,"Release",True)]:
    dfam = '"1,2"'
    if name == "Debug" and not proj:
        extra = 'SWIFT_OPTIMIZATION_LEVEL="-Onone";DEBUG_INFORMATION_FORMAT=dwarf;'
    elif name == "Release" and not proj:
        extra = 'SWIFT_OPTIMIZATION_LEVEL="-O";DEBUG_INFORMATION_FORMAT="dwarf-with-dsym";'
    else:
        extra = ""
    out.append(f"    {uid_s} = {{isa=XCBuildConfiguration;buildSettings={{PRODUCT_BUNDLE_IDENTIFIER={BID};PRODUCT_NAME=$(TARGET_NAME);SWIFT_VERSION={SV};IPHONEOS_DEPLOYMENT_TARGET={DT};TARGETED_DEVICE_FAMILY={dfam};SUPPORTS_MACCATALYST=NO;CODE_SIGNING_ALLOWED=NO;CODE_SIGNING_REQUIRED=NO;ASSETCATALOG_COMPILER_APPICON_NAME=AppIcon;INFOPLIST_FILE={PLIST};LD_RUNPATH_SEARCH_PATHS=(\"$(inherited)\",\"@executable_path/Frameworks\");ENABLE_PREVIEWS=YES;{extra}}};name={name};}};")

# Groups
out.append(f"    {MP} = {{isa=PBXGroup;children=({SP},{GRES});path=\"{P}\";sourceTree=\"<group>\";}};")
out.append(f"    {SP} = {{isa=PBXGroup;children=({', '.join(FREFS[f] for f in SRC)});path=App;sourceTree=\"<group>\";}};")
out.append(f"    {GRES} = {{isa=PBXGroup;children=({', '.join(FREFS[f] for f in RES+[PLIST])});path=Resources;sourceTree=\"<group>\";}};")

# File refs
for path in SRC:
    out.append(f"    {FREFS[path]} = {{isa=PBXFileReference;lastKnownFileType=sourcecode.swift;path={os.path.basename(path)};sourceTree=\"<group>\";}};")
for path in RES:
    out.append(f"    {FREFS[path]} = {{isa=PBXFileReference;lastKnownFileType=folder;path={os.path.basename(path)};sourceTree=\"<group>\";}};")
out.append(f"    {FREFS[PLIST]} = {{isa=PBXFileReference;lastKnownFileType=text.plist.entitlements;path={PLIST};sourceTree=\"<group>\";}};")

# Product
out.append(f"    {MF} = {{isa=PBXFileReference;explicitFileType=\"wrapper.application\";includeInIndex=0;path={P}.app;sourceTree=BUILT_PRODUCTS_DIR;}};")

# Build phases
def phase(uid, bfs, name):
    out.append(f"    {uid} = {{isa=PBX{name}BuildPhase;files=({', '.join(bfs)});runOnlyForDeploymentPostprocessing=0;}};")

phase(SB, SRC_BFS, "Sources")
phase(RB, RES_BFS, "Resources")
phase(FB, [], "Frameworks")

# Build files
for f, bf in zip(SRC, SRC_BFS):
    out.append(f"    {bf} = {{isa=PBXBuildFile;fileRef={FREFS[f]};}};")
for f, bf in zip(RES, RES_BFS):
    out.append(f"    {bf} = {{isa=PBXBuildFile;fileRef={FREFS[f]};}};")

out.append("  };")
out.append("")
out.append(f"  rootObject = {PID};")
out.append("}")

with open("/workspace/ai-translate/AI-Translate.xcodeproj/project.pbxproj", "w") as f:
    f.write("\n".join(out))
print("Generated project.pbxproj")
