PHONY: github pudding

github:
	rm -rf docs
	cp -r build docs
	touch docs/.nojekyll
	git add -A
	git commit -m "update github pages"
	git push

# aws copy exclude assets folder in build
aws-lite:
	aws s3 sync build s3://pudding.cool/2023/03/same-name --delete --exclude 'assets/*' --cache-control 'max-age=31536000'

aws-sync:
	aws s3 sync build s3://pudding.cool/2023/03/same-name --delete --cache-control 'max-age=31536000'

aws-cache:
	aws cloudfront create-invalidation --distribution-id E13X38CRR4E04D --paths '/2023/03/same-name*'	

pudding: aws-sync aws-cache

pudding-lite: aws-lite aws-cache