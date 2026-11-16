# Changelog
All notable changes to this project will be documented in this file. See [conventional commits](https://www.conventionalcommits.org/) for commit guidelines.

- - -
## [1.3.0](https://github.com/sravioli/chord.wz/compare/a71d54032294f103256c5b63991eb46b9a2183b7..1.3.0) - 2026-11-16
#### Features
- (**mosaic**) add the chord mode and hints modules - ([0dc94e8](https://github.com/sravioli/chord.wz/commit/0dc94e87d04ebfb6593dab7b327ffd831ac87ac8)) - sravioli
#### Documentation
- (**contributing**) document the signed-commit requirement - ([c52509d](https://github.com/sravioli/chord.wz/commit/c52509d10f91551ae36d3100bcdf627bf4bc90f7)) - sravioli
- (**contributing**) unify guides and templates - ([a71d540](https://github.com/sravioli/chord.wz/commit/a71d54032294f103256c5b63991eb46b9a2183b7)) - sravioli
- (**readme**) unify badge style and add release badge - ([ce288ad](https://github.com/sravioli/chord.wz/commit/ce288ad74ed0e427dc3dd39e19bb5b5e8fe3a1c4)) - sravioli
- (**readme**) align checks section - ([7000462](https://github.com/sravioli/chord.wz/commit/70004625e4f59abcbf95bc0ebb73d75151348d86)) - sravioli
- document working-tree local checkout setup - ([2da1d52](https://github.com/sravioli/chord.wz/commit/2da1d52623e032c28d8989a844cfea36351b88d3)) - sravioli
#### Continuous Integration
- build the API reference from a majority of three LuaLS runs - ([189fe19](https://github.com/sravioli/chord.wz/commit/189fe190ef3c464eeb18611397b48a77e868f89d)) - sravioli
- update the actions to the versions Dependabot proposed - ([3bd292a](https://github.com/sravioli/chord.wz/commit/3bd292a42b5e42cd6f789e3c5ae7f133dc1cb49a)) - sravioli
- pin StyLua to 2.6.0 - ([f519095](https://github.com/sravioli/chord.wz/commit/f51909504908b2f4824e7dfd8ad825f0577c1554)) - sravioli
- fix the flaky API check and the EditorConfig rate limit - ([812b062](https://github.com/sravioli/chord.wz/commit/812b0627f869f45eb0592b2c4818cd7603aafb59)) - sravioli

- - -

## [1.2.0](https://github.com/sravioli/chord.wz/compare/9850ff5c84cf5c8f45bf2ebc88e19affa4118128..1.2.0) - 2026-11-15
#### Features
- (**chord**) add temporary picker hints - ([5e7e9ee](https://github.com/sravioli/chord.wz/commit/5e7e9ee1047a9ac649de0f4336c9deb18fbecb80)) - sravioli
#### Bug Fixes
- (**hints**) clamp pagination at page boundaries - ([4c2d418](https://github.com/sravioli/chord.wz/commit/4c2d41874969bec9c9cbbd074202eb1583d19a39)) - sravioli
- (**hints**) persist page changes - ([9850ff5](https://github.com/sravioli/chord.wz/commit/9850ff5c84cf5c8f45bf2ebc88e19affa4118128)) - sravioli
#### Performance Improvements
- (**bootstrap**) keep plugin list across reloads - ([6bcbcc1](https://github.com/sravioli/chord.wz/commit/6bcbcc1631648e7c813478e92dbb352c4aa5fc87)) - sravioli
- (**bootstrap**) share plugin discovery snapshot - ([5ce1f67](https://github.com/sravioli/chord.wz/commit/5ce1f676f55643e4c565eff7ef32dc3af2480328)) - sravioli
- (**hints**) key page cache by window id - ([1ba1070](https://github.com/sravioli/chord.wz/commit/1ba1070a2f5bfcabbc7face80cda3e8b275b0875)) - sravioli
- (**hints**) cache Chord pagination layouts - ([00e56ff](https://github.com/sravioli/chord.wz/commit/00e56ff62519d4f21aac9bffaea312c1a39ff929)) - sravioli
#### Documentation
- (**readme**) update plugin READMEs - ([5e21835](https://github.com/sravioli/chord.wz/commit/5e21835f2bf47835770262349bf5f940d7bb5f62)) - sravioli
- document Chord config accessor - ([9aafb02](https://github.com/sravioli/chord.wz/commit/9aafb02017a2448ceb057f2aa82d1befff937f36)) - sravioli
#### Tests
- (**hints**) cover page cache across windows - ([80df9e4](https://github.com/sravioli/chord.wz/commit/80df9e46523354e66aad7c75eca81f79e05db166)) - sravioli

- - -

## [1.1.0](https://github.com/sravioli/chord.wz/compare/4a14c582b2d098e46d6e3fe82aaca503b96002c0..1.1.0) - 2026-05-14
#### Bug Fixes
- (**picker**) reset styled choice labels - ([8774f2b](https://github.com/sravioli/chord.wz/commit/8774f2b5a0c7eeb02b5210f316a3043581e7b896)) - sravioli
- (**picker**) ignore unresolved mode colors - ([4a14c58](https://github.com/sravioli/chord.wz/commit/4a14c582b2d098e46d6e3fe82aaca503b96002c0)) - sravioli
#### Documentation
- (**github**) add pull request templates - ([a6b9570](https://github.com/sravioli/chord.wz/commit/a6b957072eb90f1ac0ce9f162a3d9642e6b5e3dd)) - sravioli
- (**github**) polish issue templates - ([5b356bf](https://github.com/sravioli/chord.wz/commit/5b356bf1e08654dad78acd26737e1b185f603f2b)) - sravioli
- (**lua**) polish comment wording - ([14b6b50](https://github.com/sravioli/chord.wz/commit/14b6b5086b9ffcff183ebfdc5171e9ed7961f850)) - sravioli
- (**readme**) improve readme clarity - ([04a044c](https://github.com/sravioli/chord.wz/commit/04a044cb0aa3e4ee6dcb7e9584f69623316835ac)) - sravioli
#### Refactoring
- (**deps**) use warp table helpers - ([3a56282](https://github.com/sravioli/chord.wz/commit/3a5628238f4954cefbc4642dcae277eea82cd3a3)) - sravioli

- - -

## [1.0.0](https://github.com/sravioli/chord.wz/compare/740a510b718f41eed9b9074cef670de3571aa455..1.0.0) - 2026-05-11
#### Features
- (**chord**) add standalone key mapping plugin - ([740a510](https://github.com/sravioli/chord.wz/commit/740a510b718f41eed9b9074cef670de3571aa455)) - sravioli
- (**command**) generate palette entries - ([e23d360](https://github.com/sravioli/chord.wz/commit/e23d3602ad85d5b15d6dcad2ad654fc217084b9e)) - sravioli
- (**command**) style picker labels - ([e4db0b9](https://github.com/sravioli/chord.wz/commit/e4db0b9abf6e240bc903bdf50ebe4adda62aa361)) - sravioli
- (**command**) add source and table filters - ([b00de2f](https://github.com/sravioli/chord.wz/commit/b00de2fd2d3c239a465aa5a963aab7bffdb3e167)) - sravioli
- (**command**) add command picker api - ([d0d5cc1](https://github.com/sravioli/chord.wz/commit/d0d5cc18a565105f18818e888b06b3e2935be6c3)) - sravioli
- (**diagnostics**) add conflict reporting - ([6c05392](https://github.com/sravioli/chord.wz/commit/6c053928cd91545649cce064637ef076037c9c74)) - sravioli
- (**logging**) use log plugin when available - ([81a1b0a](https://github.com/sravioli/chord.wz/commit/81a1b0ad7e5d9adab59e1d8839b340a75093b781)) - sravioli
- (**overlay**) add help overlay - ([9a73136](https://github.com/sravioli/chord.wz/commit/9a7313678dadc4027baea6fc3bd8501c8166332e)) - sravioli
- (**tables**) add mode factory - ([05703e8](https://github.com/sravioli/chord.wz/commit/05703e8a7f15db0a7f56e6c0e0c789f27e249068)) - sravioli
#### Documentation
- (**chord**) add usage documentation - ([8c536ea](https://github.com/sravioli/chord.wz/commit/8c536eadfe2bc577773b5def3035813a1c674256)) - sravioli
- (**command**) document command picker - ([d374a01](https://github.com/sravioli/chord.wz/commit/d374a014a21de0c1e2d58feda4685915d57c7652)) - sravioli
- (**examples**) add command workflow config - ([90f4183](https://github.com/sravioli/chord.wz/commit/90f4183401efb33f23eb00c0426f5d0fa24bbe98)) - sravioli
- (**readme**) declare plugin dependencies - ([251fede](https://github.com/sravioli/chord.wz/commit/251fede21a37ea891cdf8c6acac6429db11b4cb4)) - sravioli
- (**readme**) restore Awesome WezTerm badge - ([8a0e7d4](https://github.com/sravioli/chord.wz/commit/8a0e7d4cc03b8e5c10d81f1cda373c59faed1a0d)) - sravioli
- (**readme**) clarify ribbon reference - ([84e017e](https://github.com/sravioli/chord.wz/commit/84e017e791823d3cfef1a84f14ccd80e44902ab2)) - sravioli
- (**readme**) hide pending upstream claims - ([dce7a71](https://github.com/sravioli/chord.wz/commit/dce7a7161eeb15f19c753d37040ecc6784495d63)) - sravioli
- (**readme**) improve readme consistency - ([5dea2b6](https://github.com/sravioli/chord.wz/commit/5dea2b626c7f3afac4959cec7bb45dd2509a0811)) - sravioli
- (**types**) annotate command APIs - ([1b979b9](https://github.com/sravioli/chord.wz/commit/1b979b9d449825a3ec7301d5bb483c6320e40d6e)) - sravioli
- document new chord APIs - ([f8658ef](https://github.com/sravioli/chord.wz/commit/f8658eff20cdc5d8faf868d2643d91be11b15deb)) - sravioli
#### Tests
- (**chord**) improve coverage for edge behavior - ([7fb2d6d](https://github.com/sravioli/chord.wz/commit/7fb2d6dab14b608a7d013419198ae7699ca5ba90)) - sravioli
- (**command**) cover picker edge cases - ([94e2ea9](https://github.com/sravioli/chord.wz/commit/94e2ea9d15edb0b55f05f360c3c750bb35b65bab)) - sravioli
- (**command**) cover command picker flows - ([21123a9](https://github.com/sravioli/chord.wz/commit/21123a9301be5a5159039c07b88a3b8d17a5e369)) - sravioli
- (**command**) support command picker mocks - ([4679dd9](https://github.com/sravioli/chord.wz/commit/4679dd935042b068e3eb5425901d7ad84b253939)) - sravioli
#### Refactoring
- (**command**) extract option helpers - ([6327eac](https://github.com/sravioli/chord.wz/commit/6327eac552b1849792c2f9caf7ae3c4121818dbb)) - sravioli
- (**command**) split picker module - ([998ea56](https://github.com/sravioli/chord.wz/commit/998ea56dfb6993f22b497cb074fd5c2d73ddaa9a)) - sravioli
- (**deps**) declare plugin metadata - ([6bf9d0f](https://github.com/sravioli/chord.wz/commit/6bf9d0ff8d46d79970afeb81a551a30cc931efda)) - sravioli

- - -

Changelog generated by [cocogitto](https://github.com/cocogitto/cocogitto).