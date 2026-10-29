Citizen skin recommended extensions bundle:

```php
<?php
wfLoadExtension('SemanticMediaWiki');
wfLoadExtension('SemanticResultFormats');
wfLoadExtension('VisualEditor');
wfLoadExtension('WikiEditor');
wfLoadExtension('PageImages');
wfLoadExtension('TextExtracts');
$wgExtractsExtendRestSearch = true;
wfLoadExtension('Popups');
wfLoadExtension('Cite');
wfLoadExtension( 'ShortDescription' );
wfLoadExtension( 'MediaSearch' );
wfLoadExtension( 'TemplateStyles' );
wfLoadExtension( 'TemplateStylesExtender' );
wfLoadExtension( 'AccountInfo' );
wfLoadExtension( 'AdvancedSearch' );
wfLoadExtension( 'CleanChanges' );
wfLoadExtension( 'CodeMirror' );
wfLoadExtension( 'SyntaxHighlight_GeSHi' );
wfLoadExtension( 'CommentStreams' );
$wgCommentStreamsEnableVoting = true;
$wgCommentStreamsNotifier = 'echo';
# <no-comment-streams /> - add to disable comments on the page
# <comment-streams /> - add to enable comments on the page
# outside of the namespaces list below
$wgCommentStreamsAllowedNamespaces = [0];
wfLoadExtension( 'Echo' );
wfLoadExtension( 'VEForAll' );
wfLoadExtension( 'Linter' );
wfLoadExtension( 'DiscussionTools' );
wfLoadExtension( 'RelatedArticles' );
wfLoadExtension( 'RevisionSlider' );
wfLoadExtension( 'TemplateData' );

wfLoadSkin( 'Citizen' );
$wgRelatedArticlesFooterAllowedSkins[] = 'citizen';
$wgDefaultSkin = 'citizen';
```
